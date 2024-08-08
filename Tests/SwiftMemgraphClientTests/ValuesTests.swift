//
//  ValuesTests.swift
//  
//
//  Created by Peter Liddle on 8/4/24.
//

import XCTest
@testable import Cmgclient
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
        case .relationship(let relatinship):
            return relatinship as? T
        default:
            fatalError("Type not currently defined for tests")
        }
    }
}

extension mg_string {

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
    
    // MARK: Bool Tests
    func testAsValueProducesTrueSwiftBool() {
        
        // Check converts true value correctly
        let testBoolValue = true
        // mg_value stores the bool as an Int32 so convert to that type before creating
        let mgBoolValueCPointer = mg_value_make_bool(Int32(testBoolValue == true ? 1 : 0))
        
        let mgBoolValueSwiftPointer = UnsafePointer<c_mg_value>(mgBoolValueCPointer)
        
        XCTAssertEqual(mgBoolValueSwiftPointer?.pointee.asValue?.value(as: Bool.self), testBoolValue)
    }
     
    
    func testAsValueProducesFalseSwiftBool() {
        // Check converts false value correctly
        let testBoolValue = false
        let mgBoolValueCPointer = mg_value_make_bool(Int32(testBoolValue == true ? 1 : 0))
        
        let mgBoolValueSwiftPointer = UnsafePointer<c_mg_value>(mgBoolValueCPointer)
        
        XCTAssertEqual(mgBoolValueSwiftPointer?.pointee.asValue?.value(as: Bool.self), testBoolValue)
        
    }
    
    // MARK: Number tests
    func testAsValueOnMgValueIntProducesSwiftIntValue() {
        let testIntValue: Int64 = 42
        let mgIntValueCPointer = mg_value_make_integer(testIntValue)
        let mgIntValueSwiftPointer = UnsafePointer<mg_value>(mgIntValueCPointer)
        
        XCTAssertEqual(mgIntValueSwiftPointer?.pointee.asValue, Value.int(testIntValue))
    }
    
    func testAsValueOnMgValueFloatProducesSwiftFloatValue() {
        let testFloatValue: Double = Double.pi
        let mgFloatValueCPointer = mg_value_make_float(testFloatValue)
        let mgFloatValueSwiftPointer = UnsafePointer<mg_value>(mgFloatValueCPointer)
        
        XCTAssertEqual(mgFloatValueSwiftPointer?.pointee.asValue, Value.float(testFloatValue))
    }
    
    // MARK: String tests
    func testAsValueOnMgStringValueProducesSwiftString() {
        
        let stringValue: String = "Hello, World!"
        let mgStringPointerB = mg_string.createMgString(from: stringValue)
        
        let mgValue = c_mg_value(type: .string, value: UnsafeRawPointer(mgStringPointerB!))
        
        XCTAssertEqual(mgValue.asValue!.value(as: String.self), stringValue)
    }
    
    // MARK: Complex values tests


    private func createMockPropertiesForTest(props: [String: Value]) -> UnsafeMutablePointer<mg_map> {
 
        let props = props.mapValues { propValue in
            switch propValue {
            case let .int(intValue):
                mg_value_make_integer(intValue)
            case let .float(floatValue):
                mg_value_make_float(Double.pi)
            case let .string(stringValue):
                mg_value_make_string(stringValue.asCStr)
            default:
                fatalError("Not implemented in test")
            }
        }
        
        let cPropMapOp = mg_map_make_empty(UInt32(props.count))
        for (key, value) in props {
            mg_map_insert(cPropMapOp, key.asCStr, value)
        }
        
        
        let cPropMap = UnsafeMutablePointer<mg_map>(cPropMapOp)
        
        return cPropMap!
    }
    
    private func createMockLabelsForTest(labels: [String]) -> UnsafeMutablePointer<UnsafeMutablePointer<mg_string>?> {
        
        func toCPointerArray<T, S>(vec: [T], convertFun: (T) -> UnsafeMutablePointer<S>) -> UnsafeMutablePointer<UnsafeMutablePointer<S>?> {
            let ptr = UnsafeMutablePointer<UnsafeMutablePointer<S>?>.allocate(capacity: vec.count)
            for (i, el) in vec.enumerated() {
                ptr[i] = convertFun(el)
            }
            return ptr
        }

        func toArrayOfStrings(vec: [String]) -> UnsafeMutablePointer<UnsafeMutablePointer<mg_string>?> {
            return toCPointerArray(vec: vec) { el in
                mg_string.createMgString(from: el)!
            }
        }
        
        return toArrayOfStrings(vec: labels)
    }
    
    func testAsValueOnMgNodeProducesSwiftNode() {
        
        let mockId: Int64 = 38927138
        
        // Create an array of mg_strings strings
        let labelStrings = ["Label1", "Label2", "Label3", "VeryVeryLongLabelToCheckIt'sAPointer", "FinalLabelOnNode"]

        // Create a dictionary of properties for testing
        let props: [String: Value] = [
            "PropKeyA": .float(Double.pi),
            "PropKeyB": .string("TestPropertyBValue"),
            "PropKeyC": .int(42)
        ]
        
        
        let cPropMap = createMockPropertiesForTest(props: props)
        
        let cMgNode = UnsafeMutablePointer<mg_node>.allocate(capacity: 1)
        cMgNode.pointee.id = mockId
        cMgNode.pointee.labelCount = UInt32(labelStrings.count)
        cMgNode.pointee.labels = createMockLabelsForTest(labels: labelStrings)
        cMgNode.pointee.properties = cPropMap
        
        let mgValueNode = mg_value_make_node(cMgNode.opaque)
        let nodePoint = UnsafePointer<mg_value>(mgValueNode)?.pointee.value
        
        guard let swiftNodeValue = mgValueNode?.to(mg_value.self).pointee.asValue as? Value else {
            XCTFail("Could not convert mg_value to swift value")
            return
        }
        
        guard let swiftNode = swiftNodeValue.value(as: Node.self) else {
            XCTFail("Could not get node from value")
            return
        }
        
        XCTAssertEqual(swiftNode.id, mockId)
        XCTAssertEqual(swiftNode.labelCount, UInt32(labelStrings.count))
        XCTAssertEqual(swiftNode.labels, labelStrings)
        XCTAssertEqual(swiftNode.properties, props)
    }
    
    
    func testAsValueOnMgRelationshipProducesSwiftRelationship() {
        
        let mockId: Int64 = 46457867342
        let startId: Int64 = 38927138
        let endId: Int64 = 281947498237
        let relationshipType = "TestTypeRelationship"
        
        // Create an array of mg_strings strings
        let labelStrings = ["Label1", "Label2", "Label3", "VeryVeryLongLabelToCheckIt'sAPointer", "FinalLabelOnNode"]

        // Create a dictionary of properties for testing
        let props: [String: Value] = [
            "PropKeyA": .float(Double.pi),
            "PropKeyB": .string("TestPropertyBValue"),
            "PropKeyC": .int(42)
        ]
        
        let cMgRelationship = mg_relationship(id: mockId, start_id: startId, end_id: endId, type: mg_string.createMgString(from: relationshipType)!,  properties: createMockPropertiesForTest(props: props))
        let mgValueNode = mg_value_make_relationship(withUnsafePointer(to: cMgRelationship, {$0.opaque}))
        
        guard let swiftRelationshipValue = mgValueNode?.to(mg_value.self).pointee.asValue as? Value else {
            XCTFail("Could not convert mg_value to swift value")
            return
        }
        
        guard let swiftRelationship = swiftRelationshipValue.value(as: Relationship.self) else {
            XCTFail("Could not get node from value")
            return
        }
        
        XCTAssertEqual(swiftRelationship.id, mockId)
        XCTAssertEqual(swiftRelationship.startId, startId)
        XCTAssertEqual(swiftRelationship.endId, endId)
        XCTAssertEqual(swiftRelationship.type, relationshipType)
        XCTAssertEqual(swiftRelationship.properties, props)
    }
}
 

final class MgStringTests: XCTestCase {
  
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
}
