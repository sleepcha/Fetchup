import Foundation

// MARK: - APIResource

/// Protocol used for REST communication in ``FetchupClient``. Represents the request data used to fetch a resource.
///
/// `body` parameter represents the data passed to `URLRequest` message body.
public protocol APIResource {
    associatedtype Response

    var method: HTTPMethod { get }
    var path: URL { get }
    var queryParameters: [String: String] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    /// Allows to set some additional `URLRequest` properties (like `timeoutInterval`) before creating a data task.
    var configure: ((inout URLRequest) -> Void)? { get }

    /// Transforms the received data to a specific instance of `Response`.
    ///
    /// The default implementation of the method is for `Decodable` kind of `Response`.
    /// For other types of data you will have to provide your own implementation.
    func decode(_ data: Data) -> Result<Response, Error>
}

public extension APIResource {
    var queryParameters: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
    var configure: ((inout URLRequest) -> Void)? { nil }
}

public extension APIResource where Response: Decodable {
    /// Default decoding implementation for JSON responses
    func decode(_ data: Data) -> Result<Response, Error> {
        data.decoded(as: Response.self)
    }
}

// MARK: - Extensions

extension URL: ExpressibleByStringLiteral {
    /// A convenience for using string literals as URLs
    public init(stringLiteral value: StaticString) {
        self.init(string: "\(value)")!
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
