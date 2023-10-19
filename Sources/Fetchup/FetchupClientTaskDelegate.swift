//
//  FetchupClientTaskDelegate.swift
//  TradeTerminal
//
//  Created by sleepcha on 4/11/23.
//

import Foundation

internal class FetchupClientTaskDelegate: NSObject {
    private var data: Data?
    private let configuration: FetchupClientConfiguration
    private let cacheMode: CacheMode
    private let completionHandler: (Result<Data, Error>) -> Void
    
    init(_ configuration: FetchupClientConfiguration, cacheMode: CacheMode, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        self.configuration = configuration
        self.cacheMode = cacheMode
        self.completionHandler = completionHandler
    }
}

extension FetchupClientTaskDelegate: URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            completionHandler(.failure(error))
            return
        }
        
        guard let response = task.response as? HTTPURLResponse else {
            let error = FetchupClientError.invalidResponse
            completionHandler(.failure(error))
            return
        }

        guard 200..<300 ~= response.statusCode else {
            if let log = configuration.loggingHandler, let url = task.originalRequest?.fullURL {
                let headers = response
                    .allHeaderFields
                    .map { "\($0.key): \($0.value)" }
                    .sorted(by: { $0 < $1 })
                    .joined(separator: "\n  ")
                log("HTTP Error \(response.statusCode) - \(url)\n[\n  \(headers)\n]")
            }
            
            let error = FetchupClientError.httpError(response)
            completionHandler(.failure(error))
            return
        }
        
        guard let data = data else {
            let error = FetchupClientError.emptyData(response)
            completionHandler(.failure(error))
            return
        }

        completionHandler(.success(data))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data == nil ? self.data = data : self.data!.append(data)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void
    ) {
        switch cacheMode {
        case .policy:
            completionHandler(proposedResponse)
        case .expires(let expirationDate):
            if var request = dataTask.currentRequest,
               let cache = session.configuration.urlCache {
                request.httpBody = dataTask.originalRequest?.httpBody
                cache.storeCachedResponse(proposedResponse.with(expirationDate), for: configuration.transformRequest(request))
            }
            completionHandler(nil)
        case .disabled:
            completionHandler(nil)
        }
    }

    // debug info to know if URLSession response originates from cache
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard
            let log = configuration.loggingHandler,
            let url = task.originalRequest?.fullURL
        else {
            return
        }
        let fetchTypes = metrics.transactionMetrics.map { fetchTypeName($0.resourceFetchType) }
        log(fetchTypes.description + " \(url)")
    }
    
    func fetchTypeName(_ fetchType: URLSessionTaskMetrics.ResourceFetchType) -> String {
        switch fetchType {
        case .unknown: return "unknown"
        case .networkLoad: return "network load"
        case .serverPush: return "server push"
        case .localCache: return "local cache"
        @unknown default: return "unsupported"
        }
    }
}

extension URLRequest {
    var fullURL: String? {
        guard let url = url?.absoluteString else { return nil }
        
        if let httpBody, let body = String(data: httpBody, encoding: .utf8) {
            return "\(url) \(body)"
        } else {
            return url
        }
    }
}
