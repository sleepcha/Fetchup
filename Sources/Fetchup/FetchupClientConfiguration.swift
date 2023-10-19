import Foundation

/// A structure used to initialize Fetchup client.
///
/// `baseURL` will be concatenated with the endpoint path.
///
/// `percentEncodingAllowedCharacters` is a set of characters that will not be percent-encoded in URL query parameters.
///
/// `loggingHandler` allows to get debug information about requests and responses (e.g. to print it out in console).
///
/// `transformRequest` gives you the opportunity to modify a request before caching it (e.g. remove/obfuscate headers containing private data, change the HTTP method, etc.).
public struct FetchupClientConfiguration {
    public let baseURL: URL?
    internal let allowedCharacters: CharacterSet
    internal let loggingHandler: ((String) -> Void)?
    internal let transformRequest: (URLRequest) -> URLRequest
    
    public init(
        /// `baseURL` will be concatenated with the endpoint path.
        baseURL: URL? = nil,
        percentEncodingAllowedCharacters: CharacterSet = .rfc3986Allowed,
        loggingHandler: ((String) -> Void)? = nil,
        transformRequest: @escaping (URLRequest) -> URLRequest = { return $0 }
    ) {
        self.baseURL = baseURL
        self.allowedCharacters = percentEncodingAllowedCharacters
        self.transformRequest = transformRequest
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
