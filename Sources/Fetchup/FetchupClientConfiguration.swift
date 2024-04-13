import Foundation

/// A structure used to initialize Fetchup client.
///
/// `baseURL` will be concatenated with the endpoint path.
///
/// `shouldInvalidateExpiredCache` if true, the client will remove the expired cached version in ``FetchupClient/cached(_:isValid:)`` method call.
///
/// `queryUnreservedCharacters` is a set of characters that will not be percent-encoded in URL query parameters.
///
/// `loggingHandler` allows to get debug information about requests and responses (e.g. to print it out in console).
///
/// `transformCachedRequest` gives you the opportunity to modify each request before caching it (e.g. remove/obfuscate headers containing private data, change the HTTP method, etc.).
///  It doest not influence the actual network request.
public struct FetchupClientConfiguration {
    public let baseURL: URL?
    let shouldInvalidateExpiredCache: Bool
    let allowedCharacters: CharacterSet
    let loggingHandler: ((String) -> Void)?
    let transform: (URLRequest) -> URLRequest

    public init(
        baseURL: URL? = nil,
        shouldInvalidateExpiredCache: Bool = true,
        queryUnreservedCharacters: CharacterSet = .rfc3986Allowed,
        loggingHandler: ((String) -> Void)? = nil,
        transformCachedRequest: @escaping (URLRequest) -> URLRequest = { $0 }
    ) {
        self.baseURL = baseURL
        self.shouldInvalidateExpiredCache = shouldInvalidateExpiredCache
        self.allowedCharacters = queryUnreservedCharacters
        self.transform = transformCachedRequest
        self.loggingHandler = loggingHandler
    }
}

// MARK: - Extensions

public extension CharacterSet {
    static var rfc3986Allowed: CharacterSet {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn: "-._~")
        return charset
    }
}
