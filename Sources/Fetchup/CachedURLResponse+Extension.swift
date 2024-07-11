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
