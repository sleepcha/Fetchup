import Foundation

public enum FetchupClientError: LocalizedError {
    case emptyResponse
    case invalidHTTPResponse(URLResponse)
    case httpError(Data?, HTTPURLResponse)
    case emptyData(HTTPURLResponse)

    public var errorDescription: String? {
        switch self {
        case .emptyResponse:
            "Empty URL response"
        case let .invalidHTTPResponse(response):
            "Invalid HTTP response\n\(response)"
        case let .httpError(_, response):
            "HTTP error \(response.statusCode) - "
        case let .emptyData(response):
            "No data received. HTTP \(response.statusCode)"
        }
    }
}
