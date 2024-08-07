//
//  CToSwiftConverterTests.swift
//  
//
//  Created by Peter Liddle on 8/6/24.
//

import XCTest
import Cmgclient
@testable import SwiftMemgraphClient

extension Dictionary where Key == String {
    
    func sortedByKeys() -> Dictionary<Key, Value> {
        let elementArray = self.sorted { $0.key.compare($1.key) == .orderedAscending }
        return Dictionary(uniqueKeysWithValues: elementArray)
    }
}


final class CToSwiftConverterTests: XCTestCase {
    
    func testMgMapToStringCMgValueSwiftDictionary() {
        
        func createMgString(from: String) -> mg_string? {
            let mgStr = mg_string_make(from.asCStr)
            return UnsafePointer<mg_string>(mgStr)?.pointee
        }
        
        func createCMgValue<T>(from value: T) -> OpaquePointer? {
            
            let valuePointer: OpaquePointer?
            
            switch value {
            case let intValue as Int64:
                valuePointer = mg_value_make_integer(intValue)
            case let stringValue as String:
                valuePointer = mg_value_make_string(stringValue)
            case let floatValue as Double:
                valuePointer = mg_value_make_float(floatValue)
            case let boolValue as Bool:
                let cBoolValue = Int32(boolValue ? 1 : 0) // Bools are stored as Int32
                valuePointer = mg_value_make_bool(cBoolValue)
            default:
                fatalError("Type not currently supported")
            }
            
            return valuePointer
        }
        
        let itemCount = 4
        
        let mockKeyA = "TestKeyA"
        let mockValueA = Int64(42)
        
        let mockKeyB = "TestKeyB"
        let mockValueB = "TestStringValue"
        
        let mockKeyC = "TestKeyC"
        let mockValueC = Double(345.6)
        
        let mockKeyD = "TestKeyD"
        let mockValueD = Bool(true)
        
        let mockTestDictionary: [String: Value] = [mockKeyA: .int(mockValueA),
                                                   mockKeyB: .string(mockValueB),
                                                   mockKeyC: .float(mockValueC),
                                                   mockKeyD: .bool(mockValueD)]
        
        let cMgMapPointer = mg_map_make_empty(UInt32(mockTestDictionary.count))
        mg_map_insert(cMgMapPointer, mockKeyA.asCStr, createCMgValue(from: mockValueA)! )
        mg_map_insert(cMgMapPointer, mockKeyB.asCStr, createCMgValue(from: mockValueB)! )
        mg_map_insert(cMgMapPointer, mockKeyC.asCStr, createCMgValue(from: mockValueC)! )
        mg_map_insert(cMgMapPointer, mockKeyD.asCStr, createCMgValue(from: mockValueD)! )
        
        let swiftDictionary = CToSwiftConverter.mgMapToStringCMgValueSwiftDictionary(mgMapCPointer: cMgMapPointer!)
        
        
        XCTAssertEqual(swiftDictionary[mockKeyA], mockTestDictionary[mockKeyA])
        XCTAssertEqual(swiftDictionary[mockKeyB], mockTestDictionary[mockKeyB])
        XCTAssertEqual(swiftDictionary[mockKeyC], mockTestDictionary[mockKeyC])
        XCTAssertEqual(swiftDictionary[mockKeyD], mockTestDictionary[mockKeyD])
    }
}
