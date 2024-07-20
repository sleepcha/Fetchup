import Foundation

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

func processResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, FetchError> {
    if let error {
        return .failure(.networkError(error))
    }

    guard let response else {
        return .failure(.emptyResponse)
    }

    guard let response = response as? HTTPURLResponse else {
        return .failure(.invalidHTTPResponse(response))
    }

    guard 200..<300 ~= response.statusCode else {
        return .failure(.httpError(data, response))
    }

    guard let data, !data.isEmpty else {
        return .failure(.emptyData(response))
    }

    return .success(data)
}
