//
//  FetchupClientConfiguration.swift
//  TinkoffStocks
//
//  Created by Jacob Chase on 3/7/23.
//

import Foundation


/// A structure used to initialize Fetchup client.
///
/// `baseURL` will be concatenated with the endpoint path.
///
/// If `manualCaching` is set to `true` no requests will be cached using URLCache except those that have a non-nil `expirationDate` property.
///
/// `modifyRequest` gives you an opportunity to modify requests before caching them (e.g. remove/obfuscate headers containing private data, change the HTTP method, etc.).
public struct FetchupClientConfiguration {
    public let baseURL: URL?
    public let manualCaching: Bool
    internal let modifyRequest: (URLRequest) -> URLRequest
    
    public init(
        baseURL: URL? = nil,
        manualCaching: Bool = false,
        modifyRequest: @escaping (URLRequest) -> URLRequest = { return $0 }
    ) {
        self.baseURL = baseURL
        self.manualCaching = manualCaching
        self.modifyRequest = modifyRequest
    }
}
