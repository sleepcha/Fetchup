import Foundation

// MARK: - FetchupClientConfiguration

/// A structure used to initialize Fetchup client.
///
/// - `baseURL` will be concatenated with the endpoint path. The default value is `nil`.
///
/// - `shouldInvalidateExpiredCache` if true, the client will remove the expired cached response in ``FetchupClient/cached(_:isValid:)`` method call. The default value is `true`.
///
/// - `queryUnreservedCharacters` is a set of characters that will not be percent-encoded in URL query parameters. The set described in RFC 3986 section 2.3 is used as a default.
///
/// - `transformCachedRequest` gives you the opportunity to modify each request before caching it.
/// For example, remove/obfuscate headers containing private data, modify the HTTP method or the URL.
/// The closure does not influence the actual network request and only used when `cacheMode` is set to `.manual`.
/// Make sure that the `URLRequest` remains unique in some way since it is used as a key in `URLCache`'s dictionary. Otherwise, you might end up retrieving an incorrect cached response.
public struct FetchupClientConfiguration {
    public let baseURL: URL?
    let shouldInvalidateExpiredCache: Bool
    let allowedCharacters: CharacterSet
    let transformingCached: (URLRequest) -> URLRequest

    public init(
        baseURL: URL? = nil,
        shouldInvalidateExpiredCache: Bool = true,
        queryUnreservedCharacters: CharacterSet = .rfc3986Allowed,
        transformCachedRequest: @escaping (URLRequest) -> URLRequest = { $0 }
    ) {
        self.baseURL = baseURL
        self.shouldInvalidateExpiredCache = shouldInvalidateExpiredCache
        self.allowedCharacters = queryUnreservedCharacters
        self.transformingCached = transformCachedRequest
    }
}

public extension CharacterSet {
    static var rfc3986Allowed: CharacterSet {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn: "-._~")
        return charset
    }
}
