import Foundation

// MARK: - FetchupClient

public protocol FetchupClient {
    var configuration: FetchupClientConfiguration { get }
    var session: URLSession { get }
}

public extension FetchupClient {
    /// Asynchronously fetches a REST resource declared in ``APIResource`` using `URLSession` and returns the result in a completion handler.
    ///
    /// - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - completion: A completion handler that passes a model object of type `Response` (associated type declared in `resource`) in case of `.success`.
    ///     Otherwise `.failure(FetchupClientError)` is passed.
    func fetchDataTask<T: APIResource>(
        _ resource: T,
        cacheMode: CacheMode = .policy,
        completion: @escaping (Result<T.Response, FetchupClientError>) -> Void
    ) -> URLSessionDataTask {
        let request = generateURLRequest(for: resource)
        let task = session.dataTask(with: request)

        task.delegate = FetchupClientTaskDelegate(configuration, cacheMode: cacheMode) {
            let result = Self.processResponse(data: $0, response: $1, error: $2)
            completion(result.flatMap(resource.decode))
        }

        return task
    }

    /// Returns a cached version of the resource.
    /// Returns `nil` if there is no entry, if it has exipred, or `cacheMode` was not set to `.manual` in `fetchDataTask`.
    ///
    /// If `shouldInvalidateExpiredCache` is set to true, expired responses will be automatically removed.
    ///
    /// - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - isValid: A closure that checks whether the cached version has expired, given the creation date of the response.
    func cached<T: APIResource>(_ resource: T, isValid: (Date) -> Bool) -> Result<T.Response, FetchupClientError>? {
        let request = generateURLRequest(for: resource, transformForCaching: true)

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
    func removeCached(_ resource: some APIResource) {
        let request = generateURLRequest(for: resource, transformForCaching: true)
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }

    private static func processResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, FetchupClientError> {
        if let error {
            return .failure(.networkError(error))
        }

        guard let response else {
            return .failure(.emptyResponse)
        }

        guard let response = response as? HTTPURLResponse else {
            return .failure(.invalidHTTPResponse(response))
        }

        guard 200..<300 ~= response.statusCode else {
            return .failure(.httpError(data, response))
        }

        guard let data, !data.isEmpty else {
            return .failure(.emptyData(response))
        }

        return .success(data)
    }

    private func generateURLRequest(for resource: some APIResource, transformForCaching: Bool = false) -> URLRequest {
        let url = resource.path
            .relative(to: configuration.baseURL)
            .appending(resource.queryParameters, notEncoding: configuration.allowedCharacters)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = resource.method.rawValue
        urlRequest.httpBody = resource.body
        resource.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        resource.configure?(&urlRequest)

        return transformForCaching ? configuration.transformingCached(urlRequest) : urlRequest
    }
}

extension CachedURLResponse {
    private static let entryDateKey = "entryDate"

    var entryDate: Date? { userInfo?[Self.entryDateKey] as? Date }

    func addingEntryDate(_ date: Date) -> CachedURLResponse {
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
