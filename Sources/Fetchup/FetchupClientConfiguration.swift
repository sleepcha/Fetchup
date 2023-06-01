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
/// If `manualCaching` is set to `true` no requests will be cached using URLCache except those that have a non-nil `expirationDate` property.
public struct FetchupClientConfiguration {
    let baseURL: URL?
    let manualCaching: Bool
    
    public init(baseURL: URL? = nil, manualCaching: Bool = false) {
        self.baseURL = baseURL
        self.manualCaching = manualCaching
    }
}
