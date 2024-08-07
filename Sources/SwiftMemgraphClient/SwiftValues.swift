//
//  SwiftValues.swift
//  This file defines basic datatypes for working with memgraph, these are designed to work well in Swift and values are converted from C structs from bound library to these types
//
//  Created by Peter Liddle on 8/5/24.
//

import Foundation

// Representation of Bolt value returned by database.
public enum Value: CustomStringConvertible {
    
    case null
    case bool(Bool)
    case int(Int64)
    case float(Float64)
    case string(String)
    case list([Value])
    case date(Date)
    case localTime(Date)
    case localDateTime(Date)
    case duration(TimeInterval)
    case map([String: Value])
    case node(Node)
    case relationship(Relationship)
    case unboundRelationship(UnboundRelationship)
    case path(Path)
    
    public var description: String {
        switch self {
        case .null:
            return "NULL"
        case .bool(let value):
            return "\(value)"
        case .int(let value):
            return "\(value)"
        case .float(let value):
            return "\(value)"
        case .string(let value):
            return "'\(value)'"
        case .date(let value):
            return "'\(value)'"
        case .localTime(let value):
            return "'\(value)'"
        case .localDateTime(let value):
            return "'\(value)'"
        case .duration(let value):
            return "'\(value)'"
        case .list(let value):
            return "\(value)"
        case .map(let value):
            return "\(value)"
        case .node(let node):
            return "\(node)"
        case .relationship(let edge):
            return "-\(edge)-"
        case .unboundRelationship(let value):
            return "\(value)"
        case .path(let value):
            return "\(value)"
        }
    }
}

extension Value: Equatable {
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            return true
        case (.bool(let lhsValue), .bool(let rhsValue)):
            return lhsValue == rhsValue
        case (.int(let lhsValue), .int(let rhsValue)):
            return lhsValue == rhsValue
        case (.float(let lhsValue), .float(let rhsValue)):
            return lhsValue == rhsValue
        case (.string(let lhsValue), .string(let rhsValue)):
            return lhsValue == rhsValue
        case (.list(let lhsValue), .list(let rhsValue)):
            return lhsValue == rhsValue
        case (.date(let lhsValue), .date(let rhsValue)):
            return lhsValue == rhsValue
        case (.localTime(let lhsValue), .localTime(let rhsValue)):
            return lhsValue == rhsValue
        case (.localDateTime(let lhsValue), .localDateTime(let rhsValue)):
            return lhsValue == rhsValue
        case (.duration(let lhsValue), .duration(let rhsValue)):
            return lhsValue == rhsValue
        case (.map(let lhsValue), .map(let rhsValue)):
            return lhsValue == rhsValue
#warning("Implement comparison for types below by adding == on those types")
            //        case (.node(let lhsValue), .node(let rhsValue)):
            //            return lhsValue == rhsValue
            //        case (.relationship(let lhsValue), .relationship(let rhsValue)):
            //            return lhsValue == rhsValue
            //        case (.unboundRelationship(let lhsValue), .unboundRelationship(let rhsValue)):
            //            return lhsValue == rhsValue
            //        case (.path(let lhsValue), .path(let rhsValue)):
            //            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

// Representation of a single row returned by database.
public struct Record {
    public var values: [Value]
}


// Representation of node value from a labeled property graph.
public struct Node: CustomStringConvertible {
    
    static let empty = Node(id: 0, labelCount: 0, labels: [], properties: [:])
    
    public var id: Int64
    public var labelCount: UInt32
    public var labels: [String]
    public var properties: [String: Value]
    
    public var description: String {
        return "(:\(labels.joined(separator: ", ")) \(properties))"
    }
}

// Representation of relationship value from a labeled property graph.
public struct Relationship: CustomStringConvertible {
    
    static let empty = Relationship(id: 0, startId: 0, endId: 0, type: "", properties: [:])
    
    public var id: Int64
    public var startId: Int64
    public var endId: Int64
    public var type: String
    public var properties: [String: Value]
    
    public var description: String {
        return "[:\(type) \(properties)]"
    }
}

// Representation of relationship from a labeled property graph.
public struct UnboundRelationship: CustomStringConvertible {
    
    static let empty = UnboundRelationship(id: 0, type: "", properties: [:])
    
    public var id: Int64
    public var type: String
    public var properties: [String: Value]
    
    public var description: String {
        return "[:\(type) \(properties)]"
    }
}

// Representation of sequence of alternating nodes and relationships corresponding to a walk in a labeled property graph.
public struct Path: CustomStringConvertible {
    
    static let empty = Path(nodeCount: 0, relationshipCount: 0, nodes: [], relationships: [])
    
    public var nodeCount: UInt32
    public var relationshipCount: UInt32
    public var nodes: [Node]
    public var relationships: [UnboundRelationship]
    
    public var description: String {
        return "Path with \(nodeCount) nodes and \(relationshipCount) relationships"
    }
}
