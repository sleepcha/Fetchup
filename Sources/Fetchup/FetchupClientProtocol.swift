import Foundation

public protocol FetchupClientProtocol {
    var configuration: FetchupClientConfiguration { get }
    var session: URLSession { get }
}

public extension FetchupClientProtocol {
    
    /// Asynchronously fetches a REST resource declared in ``APIResource`` using `URLSession` and returns the result in a completion handler.
    ///
    ///  - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - cacheMode: Tells the client how to cache the response.
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
            completion($0.flatMap(resource.decode))
        }
        
        return task
    }
    
    /// Returns or invalidates a cached version of resource depending on its expiration. Will always return `nil` if the response has been cached using `.policy` cache mode.
    func cached<T: APIResource>(_ resource: T) -> Result<T.Response, Error>? {
        let request = configuration.transformRequest(generateURLRequest(for: resource))
        
        guard let urlCache = session.configuration.urlCache,
              let response = urlCache.cachedResponse(for: request),
              let expirationDate = response.expirationDate
        else {
            return nil
        }
        
        if Date.now > expirationDate {
            urlCache.removeCachedResponse(for: request)
            return nil
        } else {
            return resource.decode(response.data)
        }
    }
    
    func removeCached<T: APIResource>(_ resource: T) {
        let request = configuration.transformRequest(generateURLRequest(for: resource))
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }
    
    private func generateURLRequest<T: APIResource>(for resource: T) -> URLRequest {
        let queryItems = resource.queryParameters.map {
            URLQueryItem(
                name: $0,
                value: $1.addingPercentEncoding(withAllowedCharacters: configuration.allowedCharacters)
            )
        }
        var url = resource.endpoint.relative(to: configuration.baseURL)
        
        if !queryItems.isEmpty {
            if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                url.append(queryItems: queryItems)
            } else {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                components.queryItems = queryItems
                url = components.url!
            }
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = resource.method.rawValue
        urlRequest.httpBody = resource.body
        resource.headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        return urlRequest
    }
}

// MARK: - Extensions

extension CachedURLResponse {
    private static let expirationDateKey = "expirationDate"
    
    var expirationDate: Date? { self.userInfo?[Self.expirationDateKey] as? Date }
    
    func with(_ expirationDate: Date) -> CachedURLResponse {
        var newUserInfo = self.userInfo ?? [:]
        newUserInfo[Self.expirationDateKey] = expirationDate
        
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
            return URL(string: baseURL.absoluteString + self.absoluteString)!
        } else {
            return self
        }
    }
}
