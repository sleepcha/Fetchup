import Foundation

public enum FetchupClientError: LocalizedError {
    case invalidResponse
    case httpError(HTTPURLResponse)
    case emptyData(HTTPURLResponse)
    
    public var errorDescription: String? {
        let httpMessage = { HTTPURLResponse.localizedString(forStatusCode: $0) }
        
        switch self {
        case .invalidResponse: return "Empty or broken HTTP response."
        case .httpError(let response): return "HTTP \(response.statusCode) - \(httpMessage(response.statusCode))"
        case .emptyData(let response): return "No data received. HTTP \(response.statusCode) - \(httpMessage(response.statusCode))"
        }
    }
}
