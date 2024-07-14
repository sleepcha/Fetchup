import Foundation

public enum FetchupClientError: LocalizedError {
    case cacheMiss
    case cacheExpired
    case emptyResponse
    case invalidHTTPResponse(URLResponse)
    case httpError(Data?, HTTPURLResponse)
    case emptyData(HTTPURLResponse)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .cacheMiss:
            "The requested item was not found in the cache."
        case .cacheExpired:
            "The cached item has expired and is no longer valid."
        case .emptyResponse:
            "Empty URL response"
        case let .invalidHTTPResponse(response):
            "Invalid HTTP response\n\(response)"
        case let .httpError(_, response):
            "HTTP error \(response.statusCode)"
        case let .emptyData(response):
            "No data received. HTTP \(response.statusCode)"
        case let .decodingError(underlyingError):
            "Unable to decode the response. \(underlyingError.localizedDescription)"
        case let .networkError(underlyingError):
            "Network error: \(underlyingError.localizedDescription)"
        }
    }
}
