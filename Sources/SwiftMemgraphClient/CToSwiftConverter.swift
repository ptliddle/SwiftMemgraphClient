//
//  CToSwiftConverter.swift
//  This file contains methods for converting from C datatypes from the bound C memgraph client library (mgclient) to Swift
//
//  Created by Peter Liddle on 8/6/24.
//

import Foundation
import Cmgclient

/// Struct to keep all methods organized for converting from C datatypes to Swift
struct CToSwiftConverter {
    
    static func cMgValueToSwiftValue(opaquePointer: OpaquePointer, cMgValue value: UnsafeRawPointer, type: c_mg_value.c_mg_value_type) -> Value? {
        switch type {
        case .null:
            return nil
        case .bool:
//            let pBool = value.assumingMemoryBound(to: Bool.self)
//            return Value.bool(pBool.pointee)
            let intBoolValue = mg_value_bool(opaquePointer)
            return Value.bool(intBoolValue == 1 ? true : false)
        case .integer:
            let intValue = mg_value_integer(opaquePointer)
            return Value.int(intValue)
        case .float:
            let floatValue = mg_value_float(opaquePointer)
            return Value.float(floatValue)
        case .string:
            let opMgString = mg_value_string(opaquePointer)
            
            guard let mgStringPointer = opMgString?.to(mg_string.self) else {
                return Value.string("")
            }
            
            let mgstring = mgStringPointer.pointee
            return Value.string(mgstring.asString)
        case .list:
            let opMgList = mg_value_list(opaquePointer)
            guard let mgList = opMgList?.to(mg_list.self) else {
                return Value.list([])
            }
            
            let list = Array(mgList.pointee.asSwiftArray())
            return Value.list(list)
        case .map:
            let opMgMap = mg_value_map(opaquePointer)
            guard let mgMap = opMgMap?.to(mg_map.self) else {
                return Value.map([:])
            }
            
            let dictionary = mgMap.pointee.asDictionary
            return Value.map(dictionary)
        case .node:
            let opNodePointer = mg_value_node(opaquePointer)
            let nodePointer = value.assumingMemoryBound(to: c_mg_node.self)
            let cValue = nodePointer.pointee
            
//            var labels = [String]()
//            if let labelsCArrayPointer = cValue.labels.pointee {
//                labels = CToSwiftConverter.mg_stringCArrayToSwiftArray(mg_stringCArrayPointer: OpaquePointer(labelsCArrayPointer), itemCount: Int(cValue.labelCount))
//                print(labels)
//            }
            
            let labels = mgCNodeLabelsToSwiftStringArray(mgNodePointer: nodePointer.opaque)
            
//            let properties = {
//               
//                let propPointer = mg_node_properties(opNodePointer)
//                let mgNodeProps = propPointer?.to(c_mg_properties.self)
//            }()
//            
            let properties = cValue.properties?.pointee.asDictionary ?? [:]
            print(properties)
            
            return .node(Node(id: cValue.id, labelCount: cValue.labelCount, labels: labels, properties: properties))
        case .relationship:
            let opNodePointer = mg_value_node(opaquePointer)
            let nodePointer = opNodePointer?.to(mg_relationship.self)
            guard let cValue = nodePointer?.pointee else {
                return Value.relationship(.empty)
            }
            
            let properties = cValue.properties.pointee.asDictionary
            
            return .relationship(Relationship(id: cValue.id, startId: cValue.start_id, endId: cValue.end_id,
                                              type: cValue.type.pointee.asString, properties: properties))
        case .unboundRelationship:
#warning("Implement unboundRelationship")
            print("unboundRelationship")
            return .unboundRelationship(.empty)
        case .path:
#warning("Implement Path")
            print("path")
            return .path(.empty)
        case .date:
#warning("Implement date")
            print("path")
            return .date(Date())
        default:
            print("Unknown value")
            return nil // return nil for now
        }
    }
    
    internal static func mgCNodeLabelsToSwiftStringArray(mgNodePointer: OpaquePointer) -> Array<String> {
        
        let cMgNode = UnsafeRawPointer(mgNodePointer).load(as: mg_node.self)
        
        var strings = [String]()
        
        for i in 0..<cMgNode.labelCount {
            let labelPoint = mg_node_label_at(mgNodePointer, UInt32(i))!.to(mg_string.self).pointee
            let labelSwift = labelPoint.asString
            print("Label \(i) read back out on node convert: \(labelSwift)")
            strings.append(labelSwift)
        }
        
        return strings
    }
    
//    /// Converts a c pointer to an array or mg_strings to a Swift array of mg_strings. Only used internally, you should use mg_stringCArrayToSwiftArray instead which returns array of swift strings
//    /// - Parameters:
//    ///   - mg_stringCArrayPointer: pointer to the mg_string array in C
//    ///   - itemCount: no of items in the array
//    /// - Returns: a Swift Array of mg_string objects
//    internal static func mg_stringCArrayToMgStringSwiftArray(mg_stringCArrayPointer: OpaquePointer, itemCount: Int) -> Array<mg_string> {
//        let mgStringStartPointer = UnsafeMutablePointer<mg_string>(mg_stringCArrayPointer)
//        let labelsBufferPointer = UnsafeMutableBufferPointer(start: mgStringStartPointer, count: itemCount)
//
//        var swiftArray = Array<mg_string>()
//
//        for i in 0..<itemCount {
//            guard let x = labelsBufferPointer.baseAddress?.advanced(by: Int(i)) else { continue }
//            swiftArray.append(x.pointee)
//        }
//
//        return swiftArray
//    }
//
//    static func mg_stringCArrayToSwiftArray(mg_stringCArrayPointer: OpaquePointer, itemCount: Int) -> Array<String> {
//        let mgStringArray = mg_stringCArrayToMgStringSwiftArray(mg_stringCArrayPointer: mg_stringCArrayPointer, itemCount: itemCount)
//        let stringArray = mgStringArray.map { $0.asString }
//        return stringArray
//    }
    
    internal static func mgListCArrayToMgListSwiftArray(mgListCArrayPointer: OpaquePointer) -> Array<c_mg_value> {
        let mgListPointer = UnsafePointer<mg_list>(mgListCArrayPointer)
        let itemCount = mgListPointer.pointee.size
        return mgListCArrayToMgListSwiftArray(mgListCArrayPointer: mgListCArrayPointer, itemCount: Int(itemCount))
    }
    
    /// Convert a C pointer to an mg_list C type containing mg_values to Swift style Array of mg_value.
    /// This should be used as an intermediate step when converting C to Swift values. This array output shouldn't be exported outside the binding library, only pass out full Swift based types
    /// - Parameters:
    ///   - mgListCArrayPointer: POinter to a C array of mg_value as an OpaquePointer so no type baggage is past just a pure pointer
    ///   - itemCount: The number of items in the C array
    /// - Returns: A Swift Array of c style mg_values.
    internal static func mgListCArrayToMgListSwiftArray(mgListCArrayPointer: OpaquePointer, itemCount: Int) -> Array<c_mg_value> {
        
        let startPointer = UnsafeMutablePointer<c_mg_value>(mgListCArrayPointer)
        let bufferPointer = UnsafeMutableBufferPointer(start: startPointer, count: itemCount)
  
        var swiftArray = Array<c_mg_value>()
        
        for i in 0..<itemCount {
            guard let x = bufferPointer.baseAddress?.advanced(by: Int(i)) else { continue }
            swiftArray.append(x.pointee)
        }
        
        return swiftArray
    }
    
    internal static func mgMapToStringCMgValueSwiftDictionary(mgMapCPointer: OpaquePointer) -> [String: Value] {
        
        var dictionary = [String: Value]()
        
        let mgTypedMapPointer = UnsafePointer<mg_map>(mgMapCPointer)
        let itemCount = mgTypedMapPointer.pointee.size
        
        for i in 0..<itemCount {
            let opKey = mg_map_key_at(mgMapCPointer, i)
            let pKey = opKey?.to(c_mg_string.self)
            
            guard let key = pKey?.pointee.asString else {
                continue
            }
            
            let value = mg_map_value_at(mgMapCPointer, i)
            
            guard let mgValue = value?.to(c_mg_value.self) else {
                dictionary[key] = Value.null
                continue
            }
            
            dictionary[key] = mgValue.pointee.asValue
        }
        
        return dictionary
    }

}
