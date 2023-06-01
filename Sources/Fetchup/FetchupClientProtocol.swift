//
//  FetchupClientProtocol.swift
//  TinkoffStocks
//
//  Created by Jacob Chase on 11/17/22.
//

import Foundation


public protocol FetchupClientProtocol {
    var defaults: FetchupClientDefaults { get }
    var session: URLSession { get }
}


public extension FetchupClientProtocol {
    
    /// Asynchronously fetches a REST resource declared in ``APIResource`` using `URLSession` and returns the result in a completion handler.
    ///
    /// The method uses ``FetchupClientDefaults/manualCaching`` to tell whether the client opts to use manual (aggresive) caching.
    ///
    ///  - Parameters:
    ///     - resource: An instance that contains the data for generating a request.
    ///     - expirationDate: Ignore if `defaults.manualCaching` is set to false. If not nil, the response will be aggressively cached with the provided expiration date.
    ///     - completion: A completion handler that passes a model object of type `Response` (decodable type declared in `resource`) in case of `.success`.
    ///     Otherwise `.failure(Error)` is passed.
    func fetchDataTask<T: APIResource>(
        _ resource: T,
        expiresOn expirationDate: Date? = nil,
        completion: @escaping T.ResultResponseHandler
    ) -> URLSessionDataTask {
        let request = generateURLRequest(for: resource)
        let task = session.dataTask(with: request)
        
        task.delegate = FetchupClientTaskDelegate(manualCaching: defaults.manualCaching, expirationDate: expirationDate) {
            completion($0.flatMap(resource.decode))
        }
        
        return task
    }
    
    /// Returns or invalidates a cached version of resource depending on its expiration. Will always return nil if ``FetchupClientDefaults/manualCaching`` is set to false.
    func cached<T: APIResource>(_ resource: T) -> T.ResultResponse? {
        guard defaults.manualCaching else { return nil }
        let request = generateURLRequest(for: resource).withGETMethod
        
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
    
    func removeCached(_ resource: some APIResource) {
        let request = generateURLRequest(for: resource).withGETMethod
        session.configuration.urlCache?.removeCachedResponse(for: request)
    }
    
    private func generateURLRequest(for resource: some APIResource) -> URLRequest {
        let queryItems = resource.queryParameters.map { URLQueryItem(name: $0, valueForPercentEncoding: $1) }
        var url = resource.endpoint.relative(to: defaults.baseURL)
        
        if !queryItems.isEmpty {
            if #available(iOS 16.0, macOS 13.0, *) {
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
        
        if let baseURL = baseURL {
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


internal extension URLRequest {
    
    /// Modifies the request method to GET.
    ///
    /// A hack for manually caching POST requests that otherwise behave like GET ones
    /// (when you're forced to pass query parameters using JSON but not query string of the URL and receive a resource that you'd like to cache).
    /// Otherwise URLCache won't retrieve cached responses to POST requests that have an HTTP body.
    var withGETMethod: URLRequest {
        var modifiedRequest = self
        modifiedRequest.httpMethod = HTTPMethod.get.rawValue
        return modifiedRequest
    }
}


extension URL: ExpressibleByStringLiteral {
    
    /// A convenience for using string values as URLs
    public init(stringLiteral value: StaticString) {
        self.init(string: "\(value)")!
    }
}
