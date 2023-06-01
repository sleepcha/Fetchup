//
//  FetchupClientTaskDelegate.swift
//  TradeTerminal
//
//  Created by Jacob Chase on 4/11/23.
//

import Foundation


internal class FetchupClientTaskDelegate: NSObject {
    private var data: Data?
    private let manualCaching: Bool
    private let expirationDate: Date?
    private let completionHandler: (Result<Data, Error>) -> Void
    
    init(manualCaching: Bool, expirationDate: Date?, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        self.manualCaching = manualCaching
        self.expirationDate = expirationDate
        self.completionHandler = completionHandler
    }
}


extension FetchupClientTaskDelegate: URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(.failure(error))
            return
        }
        
        guard let response = task.response as? HTTPURLResponse else {
            let error = FetchupClientError.invalidResponse
            completionHandler(.failure(error))
            return
        }

        guard 200..<300 ~= response.statusCode else {
            // debug info containing HTTP error code and response headers
            #if DEBUG
                let request = task.originalRequest!
                var bodyString = ""
                if let body = request.httpBody { bodyString = String(data: body, encoding: .utf8)! }

                print(response.statusCode, request, bodyString)
                print("[")
                response.allHeaderFields.forEach { print("  \($0.key): \($0.value)") }
                print("]\n")
            #endif
            
            let error = FetchupClientError.httpError(response.statusCode)
            completionHandler(.failure(error))
            return
        }
        
        guard let data = data else {
            let error = FetchupClientError.emptyData(response.statusCode)
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
        guard manualCaching
        else {
            completionHandler(proposedResponse)
            return
        }
        
        if let expirationDate,
           let request = dataTask.originalRequest?.withGETMethod,
           let cache = session.configuration.urlCache {
            cache.storeCachedResponse(proposedResponse.with(expirationDate), for: request)
        }
        
        completionHandler(nil)
    }

    // debug info to know if URLSession response originates from cache (not applicable when manualCaching)
    #if DEBUG
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        func fetchTypeName(_ fetchType: URLSessionTaskMetrics.ResourceFetchType) -> String {
            switch fetchType {
            case .unknown: return "unknown"
            case .networkLoad: return "network load"
            case .serverPush: return "server push"
            case .localCache: return "local cache"
            @unknown default: return "unsupported case"
            }
        }
            
        let fetchTypes = metrics.transactionMetrics.map { fetchTypeName($0.resourceFetchType) }
        if let url = task.response?.url {
            print(fetchTypes, url)
        }
    }
    #endif
}


internal extension CachedURLResponse {
    private var expirationDateKey: String { "expirationDate" }
    
    var expirationDate: Date? { self.userInfo?[expirationDateKey] as? Date }
    
    func with(_ expirationDate: Date) -> CachedURLResponse {
        var newUserInfo = self.userInfo ?? [:]
        newUserInfo[expirationDateKey] = expirationDate
        
        return CachedURLResponse(response: response, data: data, userInfo: newUserInfo, storagePolicy: storagePolicy)
    }
}
