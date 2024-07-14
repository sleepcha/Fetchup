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
            let result = processResponse(data: $0, response: $1, error: $2)
            completion(result.flatMap(resource.decodeMappingError))
        }

        return task
    }

    /// Returns a cached version of the resource.
    /// In case of failure `.cacheMiss`, `.cacheExpired` or `.decodingError` will be returned.
    ///
    /// If `shouldInvalidateExpiredCache` is set to true, expired responses will be automatically removed.
    ///
    /// - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - isValid: A closure that checks whether the cached version has expired, given the creation date of the response.
    func cached<T: APIResource>(_ resource: T, isValid: (Date) -> Bool) -> Result<T.Response, FetchupClientError> {
        let request = generateURLRequest(for: resource, transformForCaching: true)

        guard let urlCache = session.configuration.urlCache,
              let response = urlCache.cachedResponse(for: request),
              let entryDate = response.entryDate
        else {
            return .failure(.cacheMiss)
        }

        guard isValid(entryDate) else {
            if configuration.shouldInvalidateExpiredCache {
                urlCache.removeCachedResponse(for: request)
            }
            return .failure(.cacheExpired)
        }

        return resource.decodeMappingError(response.data)
    }

    /// Removes a cached entry if there is one.
    func removeCached(_ resource: some APIResource) {
        let request = generateURLRequest(for: resource, transformForCaching: true)
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }

    private func generateURLRequest(for resource: some APIResource, transformForCaching: Bool = false) -> URLRequest {
        let url = URL(
            string: resource.path.absoluteString,
            relativeTo: configuration.baseURL
        )!.appending(
            resource.queryParameters,
            notEncoding: configuration.allowedCharacters
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = resource.method.rawValue
        urlRequest.httpBody = resource.body
        resource.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        resource.configure?(&urlRequest)

        return transformForCaching ? configuration.transformingCached(urlRequest) : urlRequest
    }
}

private extension APIResource {
    func decodeMappingError(_ data: Data) -> Result<Response, FetchupClientError> {
        decode(data).mapError(FetchupClientError.decodingError)
    }
}
