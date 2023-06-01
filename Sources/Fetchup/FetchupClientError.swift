//
//  FetchupClientError.swift
//  TinkoffStocks
//
//  Created by Jacob Chase on 12/15/22.
//

import Foundation


public enum FetchupClientError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case emptyData(Int)
    
    public var errorDescription: String? {
        let httpMessage = { HTTPURLResponse.localizedString(forStatusCode: $0) }
        
        switch self {
        case .invalidResponse: return "Empty or broken HTTP response."
        case .httpError(let code): return "HTTP \(code) - \(httpMessage(code))"
        case .emptyData(let code): return "No data received. HTTP \(code) - \(httpMessage(code))"
        }
    }
}
