import Foundation

public protocol FetchupClientProtocol {
    var configuration: FetchupClientConfiguration { get }
    var session: URLSession { get }
}

public extension FetchupClientProtocol {
    /// Asynchronously fetches a REST resource declared in ``APIResource`` using `URLSession` and returns the result in a completion handler.
    ///
    /// - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - completion: A completion handler that passes a model object of type `Response` (associated type declared in `resource`) in case of `.success`.
    ///     Otherwise `.failure(Error)` is passed.
    func fetchDataTask<T: APIResource>(
        _ resource: T,
        cacheMode: CacheMode = .policy,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) -> URLSessionDataTask {
        let request = generateURLRequest(for: resource)
        let task = session.dataTask(with: request)

        task.delegate = FetchupClientTaskDelegate(configuration, cacheMode: cacheMode) {
            let result = Self.processResponse(data: $0, response: $1, error: $2)
            completion(result.flatMap(resource.decode))
        }

        return task
    }

    /// Returns a cached version of the resource if it has not yet expired.
    /// If `shouldInvalidateExpiredCache` is set to true, expired responses will be automatically w.
    /// Returns `nil` if there is no entry, if it has exipred, or `cacheMode` was not set to `.manual` in `fetchDataTask`.
    ///
    /// - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - isValid: A closure that checks whether the cached version has expired, given the creation date of the response.
    func cached<T: APIResource>(_ resource: T, isValid: (Date) -> Bool) -> Result<T.Response, Error>? {
        let request = configuration.transformRequest(generateURLRequest(for: resource))

        guard let urlCache = session.configuration.urlCache,
              let response = urlCache.cachedResponse(for: request),
              let entryDate = response.entryDate
        else {
            return nil
        }

        guard isValid(entryDate) else {
            if configuration.shouldInvalidateExpiredCache {
                urlCache.removeCachedResponse(for: request)
            }
            return nil
        }
        return resource.decode(response.data)
    }

    /// Removes a cached entry if there is one.
    func removeCached<T: APIResource>(_ resource: T) {
        let request = configuration.transformRequest(generateURLRequest(for: resource))
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }

    // MARK: - Private methods

    private static func processResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, Error> {
        if let error {
            return .failure(error)
        }

        guard let response else {
            return .failure(FetchupClientError.emptyResponse)
        }

        guard let response = response as? HTTPURLResponse else {
            return .failure(FetchupClientError.invalidHTTPResponse(response))
        }

        guard 200..<300 ~= response.statusCode else {
            return .failure(FetchupClientError.httpError(data, response))
        }

        guard let data else {
            return .failure(FetchupClientError.emptyData(response))
        }

        return .success(data)
    }

    private func generateURLRequest<T: APIResource>(for resource: T) -> URLRequest {
        let queryItems = resource.queryParameters
            .mapValues { $0.addingPercentEncoding(withAllowedCharacters: configuration.allowedCharacters) }
            .map(URLQueryItem.init)

        var url = resource.endpoint.relative(to: configuration.baseURL)
        if !queryItems.isEmpty { url.append(queryItems: queryItems) }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = resource.method.rawValue
        urlRequest.httpBody = resource.body
        resource.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        return urlRequest
    }
}

// MARK: - Extensions

extension CachedURLResponse {
    private static let entryDateKey = "entryDate"

    var entryDate: Date? { userInfo?[Self.entryDateKey] as? Date }

    func withEntryDate(_ date: Date) -> CachedURLResponse {
        var newUserInfo = userInfo ?? [:]
        newUserInfo[Self.entryDateKey] = date

        return CachedURLResponse(
            response: response,
            data: data,
            userInfo: newUserInfo,
            storagePolicy: storagePolicy
        )
    }
}

extension URL {
    /// Returns current URL relative to `baseURL`.
    func relative(to baseURL: URL?) -> URL {
        if let baseURL {
            return URL(string: baseURL.absoluteString + absoluteString)!
        } else {
            return self
        }
    }
}
