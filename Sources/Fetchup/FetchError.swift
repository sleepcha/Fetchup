import Foundation

public enum FetchError: LocalizedError {
    case emptyResponse
    case invalidHTTPResponse(URLResponse)
    case httpError(Data?, HTTPURLResponse)
    case emptyData(HTTPURLResponse)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .emptyResponse:
            "Empty URL response"
        case .invalidHTTPResponse(let response):
            "Invalid HTTP response\n\(response)"
        case .httpError(_, let response):
            "HTTP error \(response.statusCode)"
        case .emptyData(let response):
            "No data received. HTTP \(response.statusCode)"
        case .decodingError(let underlyingError):
            "Unable to decode the response. \(underlyingError.localizedDescription)"
        case .networkError(let underlyingError):
            "Network error: \(underlyingError.localizedDescription)"
        }
    }
}
