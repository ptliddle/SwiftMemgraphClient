//
//  SwiftTypeConversion+Extensions.swift
//  This file defines extensions to Swift types that help with converting from C types
//
//  Created by Peter Liddle on 8/6/24.
//

import Foundation


extension String {
    // Helper functions to convert between Swift and C types.
    var asCStr: UnsafePointer<CChar> {
        return (self as NSString).utf8String!
    }
    
    init(_ cString: UnsafePointer<CChar>?, _ length: Int?) {
        self = String(cString: cString!)
    }
}
