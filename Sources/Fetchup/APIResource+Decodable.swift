import Foundation

public extension APIResource where Response: Decodable {
    /// Default implementation for decoding JSON responses
    func decode(_ data: Data) -> Result<Response, Error> {
        data.decoded(as: Response.self)
    }
}

public extension Data {
    /// Returns an instance of type `T` decoded from JSON data or a `DecodingError`.
    func decoded<T: Decodable>(as type: T.Type) -> Result<T, Error> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithOptionalFractionalSeconds
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        return Result { try decoder.decode(T.self, from: self) }
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    /// Attempts to decode ISO8601 dates with *optional* fractional seconds.
    static let iso8601WithOptionalFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        if string.contains(".") { formatter.formatOptions.insert(.withFractionalSeconds) }

        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return date
    }
}
