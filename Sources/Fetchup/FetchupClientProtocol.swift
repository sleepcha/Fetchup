//
//  FetchupClientProtocol.swift
//  TinkoffStocks
//
//  Created by Jacob Chase on 11/17/22.
//

import Foundation


public protocol FetchupClientProtocol {
    var configuration: FetchupClientConfiguration { get }
    var session: URLSession { get }
}


public extension FetchupClientProtocol {
    
    /// Asynchronously fetches a REST resource declared in ``APIResource`` using `URLSession` and returns the result in a completion handler.
    ///
    /// The method uses ``FetchupClientConfiguration/manualCaching`` to tell whether the client opts to use manual (aggresive) caching.
    ///
    ///  - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - expirationDate: Ignore if `configuration.manualCaching` is set to false. Otherwise if not nil, the response will be aggressively cached with the provided expiration date.
    ///     - completion: A completion handler that passes a model object of type `Response` (associated type declared in `resource`) in case of `.success`.
    ///     Otherwise `.failure(Error)` is passed.
    func fetchDataTask<T: APIResource>(
        _ resource: T,
        expiresOn expirationDate: Date? = nil,
        completion: @escaping (Result<T.Response, Error>) -> Void
    ) -> URLSessionDataTask {
        let request = generateURLRequest(for: resource)
        let task = session.dataTask(with: request)
        
        task.delegate = FetchupClientTaskDelegate(configuration, expirationDate: expirationDate) {
            completion($0.flatMap(resource.decode))
        }
        
        return task
    }
    
    /// Returns or invalidates a cached version of resource depending on its expiration. Will always return nil if ``FetchupClientConfiguration/manualCaching`` is set to false.
    func cached<T: APIResource>(_ resource: T) -> Result<T.Response, Error>? {
        guard configuration.manualCaching else { return nil }
        let request = configuration.modifyRequest(generateURLRequest(for: resource))
        
        guard let cache = session.configuration.urlCache,
              let response = cache.cachedResponse(for: request),
              let expirationDate = response.expirationDate
        else {
            return nil
        }
        
        if Date.now > expirationDate {
            cache.removeCachedResponse(for: request)
            return nil
        } else {
            return resource.decode(response.data)
        }
    }
    
    func removeCached<T: APIResource>(_ resource: T) {
        let request = configuration.modifyRequest(generateURLRequest(for: resource))
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }
    
    private func generateURLRequest<T: APIResource>(for resource: T) -> URLRequest {
        let queryItems = resource.queryParameters.map { URLQueryItem(name: $0, valueForPercentEncoding: $1) }
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


private extension URL {
    
    /// Returns current URL relative to `baseURL`. If `baseURL` is nil the original URL is returned.
    func relative(to baseURL: URL?) -> URL {
        if let baseURL {
            return URL(string: baseURL.absoluteString + self.absoluteString)!
        } else {
            return self
        }
    }
}


private extension URLQueryItem {
    init(name: String, valueForPercentEncoding value: String) {
        var rfc3986Allowed: CharacterSet {
            var rfc3986 = CharacterSet.alphanumerics
            rfc3986.insert(charactersIn: "-._~")
            return rfc3986
        }
        
        self.init(name: name, value: value.addingPercentEncoding(withAllowedCharacters: rfc3986Allowed))
    }
}


extension URL: ExpressibleByStringLiteral {
    
    /// A convenience for using string values as URLs
    public init(stringLiteral value: StaticString) {
        self.init(string: "\(value)")!
    }
}
