import Foundation

public extension URL {
    /// Returns current URL relative to `baseURL`.
    func relative(to baseURL: URL?) -> URL {
        if let baseURL {
            URL(string: baseURL.absoluteString + absoluteString)!
        } else {
            self
        }
    }

    func appending(_ queryParameters: [String: String], notEncoding allowedCharacters: CharacterSet) -> URL {
        guard !queryParameters.isEmpty else { return self }

        let queryItems = queryParameters
            .mapValues { $0.addingPercentEncoding(withAllowedCharacters: allowedCharacters) }
            .map(URLQueryItem.init)

        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        components.percentEncodedQueryItems = components.percentEncodedQueryItems ?? []
        components.percentEncodedQueryItems?.append(contentsOf: queryItems)
        return components.url!
    }
}

// MARK: - URL + ExpressibleByStringLiteral

extension URL: ExpressibleByStringLiteral {
    /// A convenience for using string literals as URLs
    public init(stringLiteral value: StaticString) {
        self.init(string: "\(value)")!
    }
}
