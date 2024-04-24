import Foundation

// MARK: - FetchupClientTaskDelegate

class FetchupClientTaskDelegate: NSObject {
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

// MARK: - URLSessionTaskDelegate, URLSessionDataDelegate

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
                cache.storeCachedResponse(proposedResponse.withEntryDate(Date()), for: configuration.transformCached(request))
            }
            completionHandler(nil)
        case .disabled:
            completionHandler(nil)
        }
    }
}
