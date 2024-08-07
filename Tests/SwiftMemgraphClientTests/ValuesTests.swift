//
//  ValuesTests.swift
//  
//
//  Created by Peter Liddle on 8/4/24.
//

import XCTest
import Cmgclient
@testable import SwiftMemgraphClient
import Foundation

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        
        switch (lhs, rhs) {
        case (.int(let valA), .int(let valB)):
            return valA == valB
        case (.float(let valA), .float(let valB)):
            return valA == valB
        case (.string(let valA), .string(let valB)):
            return valA == valB
        default:
            return false
        }
    }
}

final class MgMapTests: XCTestCase {
//    func test_c_map_ToSwiftDictionary() {
//        
//        // Create sample C strings and values
//        let sampleKey1 = "key1"
//        let sampleKey2 = "key2"
//        let sampleValue1 = c_mg_value.c_mg_value_type(rawValue: 42)
//        let sampleValue2 = c_mg_value.c_mg_value_type(rawValue: 42)
//        
//        // Allocate memory for the C strings
//        let cStringPointer1 = strdup(sampleKey1)
//        let cStringPointer2 = strdup(sampleKey2)
//        
//        // Ensure the pointers are not nil
//        XCTAssertNotNil(cStringPointer1)
//        XCTAssertNotNil(cStringPointer2)
//        
//        // Create c_mg_string instances
//        let mgString1 = mg_string(size: UInt32(strlen(sampleKey1)), data: cStringPointer1!)
//        let mgString2 = mg_string(size: UInt32(strlen(sampleKey2)), data: cStringPointer2!)
//        
//        // Allocate memory for the keys and values arrays
//        let keysArray = UnsafeMutablePointer<UnsafePointer<c_mg_string>?>.allocate(capacity: 2)
//        let valuesArray = UnsafeMutablePointer<UnsafePointer<c_mg_value>?>.allocate(capacity: 2)
//        
//        // Assign the keys and values
//        keysArray[0] = UnsafePointer(mgString1)
//        keysArray[1] = UnsafePointer(mgString2)
//        valuesArray[0] = UnsafePointer(sampleValue1)
//        valuesArray[1] = UnsafePointer(sampleValue2)
//        
//        // Create an instance of c_mg_map
//        let mgMap = mg_map(size: 2, capacity: 2, keys: UnsafePointer(keysArray), values: UnsafePointer(valuesArray))
//        
//        // Test the asDictionary property
//        let expectedDictionary: [String: Value] = [
//            sampleKey1: Value(intValue: 42),
//            sampleKey2: Value(intValue: 84)
//        ]
//        XCTAssertEqual(mgMap.asDictionary, expectedDictionary)
//        
//        // Free the allocated memory
//        free(cStringPointer1)
//        free(cStringPointer2)
//        keysArray.deallocate()
//        valuesArray.deallocate()
//    }
}


extension Value {
    func value<T>(as oType: T.Type) -> T? {
        switch self {
        case .null:
            return nil
        case .bool(let bool):
            return bool as? T
        case .string(let string):
            return string as? T
        case .int(let int):
            return int as? T
        case .float(let float):
            return float as? T
        case .node(let node):
            return node as? T
        default:
            fatalError("Type not defined")
        }
    }
}

extension mg_string {
//    static func from(_ stringValue: String) -> UnsafeMutablePointer<mg_string> {
////        let stringPointer = UnsafeMutablePointer<String>.allocate(capacity: 1)
////        stringPointer.pointee = stringValue
//        
//        let mgStringPointer = UnsafeMutablePointer<mg_string>.allocate(capacity: 1)
//        let cStr = stringValue.cString(using: .utf8)!
//        mgStringPointer.pointee.data = UnsafePointer(cStr)
//        mgStringPointer.pointee.size = UInt32(cStr.count)
//        
//        return mgStringPointer
//    }
//    
    // Function to create an mg_string from a Swift string and return a pointer to it
    static func createMgString(from string: String) -> UnsafeMutablePointer<mg_string>? {
        // Convert the Swift string to a C string
        let cStr = strdup(string)
        
        // Allocate memory for the mg_string struct
        let mgStringPointer = UnsafeMutablePointer<mg_string>.allocate(capacity: 1)
        
        // Initialize the mg_string struct
        mgStringPointer.pointee.data = UnsafePointer<CChar>(cStr!)
        mgStringPointer.pointee.size = UInt32(strlen(cStr!))
        
        return mgStringPointer
    }
    
    static func mg_string_list(from strings: [String]) -> UnsafeMutableBufferPointer<mg_string> {
        var labelBufferPointer = UnsafeMutableBufferPointer<mg_string>.allocate(capacity: strings.count)
        
        strings.enumerated().forEach { element in
            let (index, string) = element
            let p_mg_string = mg_string.createMgString(from: string)
            guard let mg_string = p_mg_string?.pointee else { fatalError("Failed to make mg_string") }
            labelBufferPointer.baseAddress?.advanced(by: index).pointee = mg_string
        }
        
        return labelBufferPointer
    }
    
    static func mgListArray(from bufferPointer: UnsafeMutableBufferPointer<mg_string>, noItems: Int) -> Array<mg_string>? {
        var mg_strings_array = Array<mg_string>()
        guard let baseAddr = bufferPointer.baseAddress else { return nil }
        
        for i in 0..<noItems {
            mg_strings_array.append(baseAddr.advanced(by: i).pointee)
        }
        return mg_strings_array
    }
}

final class CDataCreator {
    
    static func stringArrayToMgStringCArray(strings: [String]) -> UnsafeMutableBufferPointer<mg_string> {
        
        var labelBufferPointer = UnsafeMutableBufferPointer<mg_string>.allocate(capacity: strings.count)
        
        strings.enumerated().forEach { element in
            let (index, string) = element
            let p_mg_string = mg_string.createMgString(from: string)
            guard let mg_string = p_mg_string?.pointee else { fatalError("Failed to make mg_string") }
            labelBufferPointer.baseAddress?.advanced(by: index).pointee = mg_string
        }
        
        var mgStringsPointer = mg_string.mg_string_list(from: strings)
        
        return mgStringsPointer
    }
}

final class MgValueTests: XCTestCase {
    
    func testAsValueBool() {
        
        // Check set to true
        var boolValue: Bool = true
        let boolPointer = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        boolPointer.pointee = boolValue
        
        let mgValue = c_mg_value(type: .bool, value: UnsafeRawPointer(boolPointer))
        
        XCTAssertEqual(mgValue.asValue?.value(as: Bool.self), boolValue)
        
        
        // Check set to false
        boolValue = false
        boolPointer.pointee = boolValue
        
        let mgValue2 = c_mg_value(type: .bool, value: UnsafeRawPointer(boolPointer))
        
        XCTAssertEqual(mgValue2.asValue?.value(as: Bool.self), boolValue)
        
        boolPointer.deallocate()
    }
    
    func testAsValueInt() {
        let intValue: Int64 = 42
        let intPointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        intPointer.pointee = intValue
        
        let mgValue = c_mg_value(type: .integer, value: UnsafeRawPointer(intPointer))
        let mgNumber = mgValue.asValue!.value(as: Int64.self)
        XCTAssertEqual(mgNumber, intValue)
        
        intPointer.deallocate()
    }
    
    func testAsValueFloat() {
        let floatValue: Double = 3.14
        let floatPointer = UnsafeMutablePointer<Double>.allocate(capacity: 1)
        floatPointer.pointee = floatValue
        
        let mgValue = c_mg_value(type: .float, value: UnsafeRawPointer(floatPointer))
        let mgFloat = mgValue.asValue!.value(as: Double.self)
        
        XCTAssertEqual(mgFloat, floatValue)
        
        floatPointer.deallocate()
    }
    
    func testAsValueString() {
        
        let stringValue: String = "Hello, World!"
//        let stringPointer = UnsafeMutablePointer<String>.allocate(capacity: 1)
//        stringPointer.pointee = stringValue
//        
//        let mgStringPointer = UnsafeMutablePointer<mg_string>.allocate(capacity: 1)
//        let cStr = stringValue.cString(using: .utf8)!
//        mgStringPointer.pointee.data = withUnsafePointer(to: cStr, { $0.pointee })
//        mgStringPointer.pointee.size = UInt32(cStr.count)
        
        let mgStringPointerB = mg_string.createMgString(from: stringValue)
        
        let mgValue = c_mg_value(type: .string, value: UnsafeRawPointer(mgStringPointerB!))
        
        XCTAssertEqual(mgValue.asValue!.value(as: String.self), stringValue)

        mgStringPointerB!.deallocate()
//        stringPointer.deallocate()
    }
    
    #warning("Get this working, need to figure out how to get the right pointer into the mg_node labels and properties")
    func testAsValueNode() {
        
        
        let mockId: Int64 = 38927138
        
        // Create an array of mg_strings strings
        let labelStrings = ["Label1", "Label2", "Label3", "VeryVeryLongLabelToCheckIt'sAPointer", "FinalLabelOnNode"]
        
//        var labelBufferPointer = UnsafeMutableBufferPointer<mg_string>.allocate(capacity: labelStrings.count)
//        
//        labelStrings.enumerated().forEach { element in
//            let (index, string) = element
//            let p_mg_string = mg_string.createMgString(from: string)
//            guard let mg_string = p_mg_string?.pointee else { fatalError("Failed to make mg_string") }
//            labelBufferPointer.baseAddress?.advanced(by: index).pointee = mg_string
//        }
//        
//        let mgStringsPointer = mg_string.mg_string_list(from: labelStrings)
//
//        labelStrings.enumerated().forEach { element in
//            let (i, _ ) = element
//            print(labelBufferPointer.baseAddress?.advanced(by: i).pointee)
//            print(mgStringsPointer.baseAddress?.advanced(by: i).pointee)
//        }
//        
//        var mg_string_list = mg_string.mgListArray(from: mgStringsPointer, noItems: labelStrings.count)
//        print(mg_string_list)
//        
//        let labelPointer = UnsafeMutablePointer<UnsafeMutablePointer<mg_string>?>(OpaquePointer(mgStringsPointer.baseAddress!))
        
        let labelsCArrayPointer = CDataCreator.stringArrayToMgStringCArray(strings: labelStrings)
        guard let op = OpaquePointer(labelsCArrayPointer.baseAddress) else { fatalError("Opaque Pointer to labels failed") }
        
        let mg_node = mg_node(id: mockId, labelCount: UInt32(labelStrings.count), labels: UnsafeMutablePointer<Optional<UnsafeMutablePointer<c_mg_string>>>(op))
        
        let mg_value = c_mg_value(type: .node, value: withUnsafePointer(to: mg_node, {$0}))
        
        let mgValue = mg_value.asValue!
        let node = mgValue.value(as: Node.self)
        XCTAssertEqual(node!.id, mockId)
//        XCTAssertEqual(node!.labelCount, labelStrings.count)
        XCTAssertEqual(node!.labels, labelStrings)
    }
}


final class MgStringTests: XCTestCase {
  
    #warning("This doesn't seem to be working correctly")
    func testMgStringNotNullTerminatedToSwiftString() {
        
        let sampleCString = "Hello, World! Not Null Terminated"

        // Convert the Swift string to a C string without the null terminator
        let cStringWithoutNullTerminator = sampleCString.utf8CString.dropLast()

        // Allocate memory for the C string without the null terminator
        let cStringPointer = UnsafeMutablePointer<CChar>.allocate(capacity: cStringWithoutNullTerminator.count)

        // Copy the characters to the allocated memory
        for (index, char) in cStringWithoutNullTerminator.enumerated() {
            cStringPointer[index] = char
        }
        
        // Create an instance of c_mg_string
        let mgString = mg_string(size: UInt32(strlen(sampleCString)), data: cStringPointer)
        
        // Test the asString property
        XCTAssertEqual(mgString.asString, sampleCString)
        
        // Free the allocated memory
        free(cStringPointer)
    }
    
    func testMgStringToSwiftString() {
        // Create a sample C string
        let sampleCString = "Hello, World!"
        
        // Allocate memory for the C string
        let cStringPointer = strdup(sampleCString)
        
        // Ensure the pointer is not nil
        XCTAssertNotNil(cStringPointer)
        
        // Create an instance of c_mg_string
        let mgString = mg_string(size: UInt32(strlen(sampleCString)), data: cStringPointer!)
        
        // Test the asString property
        XCTAssertEqual(mgString.asString, sampleCString)
        
        // Free the allocated memory
        free(cStringPointer)
    }
    
    
    func testMgStringCArrayToSwiftArray() {
        let testStrings = ["Item 1", "Test String That's Slightly Longer", "Another Test String"]
        let mgStringCArrayPointer = CDataCreator.stringArrayToMgStringCArray(strings: testStrings )
        let op = OpaquePointer(mgStringCArrayPointer.baseAddress)
        let outputSwiftStrings = CToSwiftConverter.mg_stringCArrayToSwiftArray(mg_stringCArrayPointer: op!, itemCount: testStrings.count)
        
        XCTAssertEqual(testStrings[0], outputSwiftStrings[0])
        XCTAssertEqual(testStrings[1], outputSwiftStrings[1])
        XCTAssertEqual(testStrings[2], outputSwiftStrings[2])
    }
    
}

/// Tests to check the values map correctly from C to Swift and vice versa
final class ValuesTests: XCTestCase {
    
//    func testCheckPropertiesMapFromCToSwiftDict() {
//        
//        // Create mock keys
//        let key1 = mg_string(size: .max, data: ("key1" as NSString).utf8String!)
//        let key2 = mg_string(size: .max, data: ("key2" as NSString).utf8String!)
//        let key3 = mg_string(size: .max, data: ("key3" as NSString).utf8String!)
//        let keys = [key1, key2, key3]
//            
//        // Create mock values
//        let val1 = 42
//        let value1 = c_mg_value(type: .integer, value: withUnsafePointer(to: val1, {$0}))
//        let val2 = Float(3.14)
//        let value2 = c_mg_value(type: .float, value: withUnsafePointer(to: val2, {$0}))
//        let val3 = "TestValue"
//        let value3 = c_mg_value(type: .string, value: withUnsafePointer(to: val3, {$0}))
//        let values = [value1, value2, value3]
//        
//        // Convert arrays to UnsafePointer
////        let keysPointer = withUnsafePointer(to: keys, {$0})
////        let valuesPointer = withUnsafePointer(to: values, {$0})
//        let keysPointer = keys.withUnsafeBufferPointer({ $0.baseAddress! })
//        let valuesPointer = values.withUnsafeBufferPointer({ $0.baseAddress! })
//        
//        // Create c_mg_map instance
//        let map = c_mg_map(size: UInt32(values.count), capacity: UInt32(values.count), keys: keysPointer, values: valuesPointer)
//        
//        // Convert to dictionary
//        let dictionary = map.asDictionary
//        
//        // Expected dictionary
//        let expectedDictionary: [String: Value] = [
//            "key1": .int(42),
//            "key2": .date(Date.now),
//            "key3": .string("TestValue")
//        ]
//        
//        // Assert equality
//        XCTAssertEqual(dictionary.count, expectedDictionary.count)
//        expectedDictionary.forEach { element in
//            let (key, value) = element
//            XCTAssertEqual(value, dictionary[key])
//        }
//    }
    
//    func testCheckPropertiesMapFromCToSwiftDict() {
//        
//        let testDictionary = [
//            "keyA": Value.string("Test Value A"),
//            "keyB": Value.bool(false),
//            "keyC": Value.int(45)
//        ]
//        
//        let capacity = UInt32.max // Not used by swift
//        
//        let keysAsMsg = [String](testDictionary.keys).map({ x in
//            let cString = strToCStr(x)
//            return mg_string(size: .max, data: cString)
//        })
//        
//        let keys = withUnsafePointer(to: keysAsMsg, { $0 })
//        let values = withUnsafePointer(to: testDictionary.values, { $0 })
//        
//        let cMap = c_mg_map(size: UInt32(testDictionary.count), capacity: capacity, keys: keys, values: values)
//        
//        
//    }
    
}
