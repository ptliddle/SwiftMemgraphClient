//
//  Error.swift
//
//
//  Created by Peter Liddle on 8/4/24.
//

import Foundation

/// Error returned by using connection.
public struct MgError: Error, CustomStringConvertible {
    public let message: String

    public init(message: String) {
        self.init(message)
    }
    
    public init(_ message: String) {
        self.message = message
    }

    public var description: String {
        return message
    }
}
 
