import Foundation

public enum CacheError: LocalizedError {
    case cacheMiss
    case cacheExpired
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .cacheMiss:
            "The requested item was not found in the cache."
        case .cacheExpired:
            "The cached item has expired and is no longer valid."
        case .decodingError(let underlyingError):
            "Unable to decode the response. \(underlyingError.localizedDescription)"
        }
    }
}
