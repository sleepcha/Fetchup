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

    /// Decodes the received data into a specific instance of `Response`.
    func decode(_ data: Data) -> Result<Response, Error>
}

public extension APIResource {
    var queryParameters: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
    var configure: ((inout URLRequest) -> Void)? { nil }
}
