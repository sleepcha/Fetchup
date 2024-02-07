import Foundation

internal class FetchupClientTaskDelegate: NSObject {
    private let configuration: FetchupClientConfiguration
    private let cacheMode: CacheMode
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var receivedData = Data()

    init(_ configuration: FetchupClientConfiguration, cacheMode: CacheMode, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.configuration = configuration
        self.cacheMode = cacheMode
        self.completionHandler = completionHandler
    }
}

extension FetchupClientTaskDelegate: URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completionHandler(receivedData, task.response, error)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
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
        case .manual:
            if var request = dataTask.currentRequest,
               let cache = session.configuration.urlCache {
                request.httpBody = dataTask.originalRequest?.httpBody
                cache.storeCachedResponse(proposedResponse.withEntryDate(Date.now), for: configuration.transformRequest(request))
            }
            completionHandler(nil)
        case .disabled:
            completionHandler(nil)
        }
    }

    // debug info to know if URLSession response originates from cache
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        func fetchTypeName(_ fetchType: URLSessionTaskMetrics.ResourceFetchType) -> String {
            switch fetchType {
            case .unknown: "unknown"
            case .networkLoad: "network load"
            case .serverPush: "server push"
            case .localCache: "local cache"
            @unknown default: "unsupported"
            }
        }

        guard
            let log = configuration.loggingHandler,
            let url = task.originalRequest?.fullURL
        else {
            return
        }
        let fetchTypes = metrics.transactionMetrics.map { fetchTypeName($0.resourceFetchType) }
        log(fetchTypes.description + " \(url)")
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
