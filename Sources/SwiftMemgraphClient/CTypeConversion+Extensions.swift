//
//  CTypeConversion+Extensions.swift
//  This file defines extensions to C types adding conversion functions so they are easier to find on the objects then calling static functions in CToSwiftConverter
//  Having a seperate file keeps these seperate from the CValues and allows for these to exist independent of CValue definitions in case they can be exported from C
//
//  Created by Peter Liddle on 8/6/24.
//

import Foundation
import Cmgclient

protocol HasOpagueCPointer {
    var opaquePointer: OpaquePointer { get }
}

extension HasOpagueCPointer {
    var opaquePointer: OpaquePointer {
        return withUnsafePointer(to: self, { $0 }).opaque
    }
}

extension c_mg_string {
    var asString: String {
        let string = String(cString: data)
        
        if string.count == size { // Add one to account for null terminator in mg_string size value
            return string
        }
        else {
            // This deals with the occasional situation where we get a string with no null terminator
            return String(bytesNoCopy: UnsafeMutableRawPointer(mutating: data), length: Int(size), encoding: .utf8, freeWhenDone: false) ?? ""
        }
    }
}

extension c_mg_value: HasOpagueCPointer {
    var asValue: Value? {
        CToSwiftConverter.cMgValueToSwiftValue(opaquePointer: self.opaquePointer, cMgValue: self.value, type: self.type)
    }
}

extension c_mg_list {
    static func convertToValues(_ mgListPointer: UnsafePointer<mg_list>? ) -> [Value]? {
        
        guard let mgListPointer = mgListPointer else { return nil }
        
        // Get a pointer to the elements
        let mg_list = mgListPointer.pointee
        let itemCount = Int(mg_list.size)
        let bufferPointer = UnsafeBufferPointer(start: mg_list.elements, count: itemCount)
  
        var swiftArray = [Value]()
        
        for i in 0..<itemCount {
            let x = bufferPointer[i]
            swiftArray.append(x.pointee.asValue ?? Value.null)
        }
        
        return swiftArray
    }
    
    private func element(_ at: UInt32) -> c_mg_value? {
        let op = OpaquePointer(withUnsafePointer(to: self, {$0}))
        let pointer = mg_list_at(op, at)
        return UnsafePointer<c_mg_value>(pointer)?.pointee
    }
    
    private var opaguePointer: OpaquePointer {
        return withUnsafePointer(to: self, { $0 }).opaque
    }
    
    public func asSwiftArray() -> [Value] {
  
        let mgList = CToSwiftConverter.mgListCArrayToMgListSwiftArray(mgListCArrayPointer: self.elements.opaque, itemCount: Int(self.size))
         
        let values = mgList.map({ $0.asValue ?? Value.null })
        
        return values
    }
}

extension c_mg_map {
    var asDictionary: [String: Value] {
        CToSwiftConverter.mgMapToStringCMgValueSwiftDictionary(mgMapCPointer: self.opaquePointer)
    }
}
