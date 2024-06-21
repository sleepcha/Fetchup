import Foundation

public enum FetchupClientError: LocalizedError {
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
        case let .invalidHTTPResponse(response):
            "Invalid HTTP response\n\(response)"
        case let .httpError(_, response):
            "HTTP error \(response.statusCode)"
        case let .emptyData(response):
            "No data received. HTTP \(response.statusCode)"
        case let .decodingError(error):
            "Unable to decode the response: \(error.localizedDescription)"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
