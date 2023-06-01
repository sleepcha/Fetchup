//
//  APIResource.swift
//  TinkoffStocks
//
//  Created by Jacob Chase on 12/13/22.
//

import Foundation


/// Protocol used for REST communication in ``FetchupClientProtocol``. Represents the request data used to fetch a resource.
///
/// `body` parameter represents the data passed to `URLRequest` message body.
public protocol APIResource {
    associatedtype Response
    typealias ResultResponse = Result<Response, Error>
    typealias ResultResponseHandler = (Result<Response, Error>) -> Void
    
    var method: HTTPMethod { get }
    var endpoint: URL { get }
    
    var queryParameters: [String: String] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    
    /// Transforms the received data to a specific instance of `Response`.
    ///
    /// The default implementation of the method is for `Decodable` kind of `Response`.
    /// For other kinds of data you will have to provide your own implementation.
    func decode(_ data: Data) -> ResultResponse
}


public extension APIResource {
    // optional properties (e.g. a simple GET request with no params or body)
    var queryParameters: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
}


/// Default decoding implementation for JSON responses
public extension APIResource where Response: Decodable {
    func decode(_ data: Data) -> ResultResponse {
        return data.decoded(as: Response.self)
    }
}


private extension Data {
    
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
    static let iso8601WithOptionalFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)

        // try to decode dates in JSON with *optional* fractional seconds
        let formatter = ISO8601DateFormatter()
        if string.contains(".") { formatter.formatOptions.insert(.withFractionalSeconds) }
        
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return date
    }
}
