import Foundation

extension CachedURLResponse {
    private static let entryDateKey = "entryDate"

    var entryDate: Date? { userInfo?[Self.entryDateKey] as? Date }

    func addingEntryDate(_ date: Date) -> CachedURLResponse {
        var newUserInfo = userInfo ?? [:]
        newUserInfo[Self.entryDateKey] = date

        return CachedURLResponse(
            response: response,
            data: data,
            userInfo: newUserInfo,
            storagePolicy: storagePolicy
        )
    }
}

public extension URL {
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
