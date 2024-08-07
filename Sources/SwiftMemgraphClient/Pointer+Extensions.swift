//
//  Pointer+Extensions.swift
//  
//
//  Created by Peter Liddle on 8/5/24.
//

import Foundation

extension OpaquePointer {
    func to<T>(_ oType: T.Type) -> UnsafePointer<T> {
        return UnsafePointer<T>(self)
    }
}

extension UnsafePointer {
    var opaque: OpaquePointer {
        return OpaquePointer(self)
    }
}

extension UnsafeRawPointer {
    var opaque: OpaquePointer {
        return OpaquePointer(self)
    }
}
