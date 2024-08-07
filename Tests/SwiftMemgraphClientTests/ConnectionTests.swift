//
//  ConnectionTests.swift
//
//
//  Created by Peter Liddle on 8/5/24.
//

import XCTest
@testable import SwiftMemgraphClient
import Cmgclient


/// These tests require a connection to a live database instance
/// You can change the parameters below to point to a different endpoint or fire up a default memgraph docker container and connect with the default parameters
///
final class ConnectionTests: XCTestCase {

    func testMgClientConnects() throws {
        let connectParams = ConnectParams(host: "localhost")
        let mgclient = try Connection.connect(params: connectParams)
        XCTAssertEqual(mgclient.status, ConnectionStatus.ready)
    }
    
    private func getReadyConnection(lazyFetch: Bool = false) throws -> Connection {
        let connectParams = ConnectParams(host: "localhost", lazy: lazyFetch, autocommit: true)
        let mgConnection = try Connection.connect(params: connectParams)
        XCTAssertEqual(mgConnection.status, ConnectionStatus.ready)
        return mgConnection
    }
    
    func testMgClientExecuteQueryAndFetchAll() throws {
        
        let connection = try getReadyConnection()
        
        let query = String("MATCH (n) RETURN (n);");
        let result = try connection.execute(query: query, params: [:])
        print(result)
    }
    
    func testMgClientExecuteQueryAndFetchAndReturnAll() throws {
        
        let connection = try getReadyConnection()
        
        let query = String("MATCH (n) RETURN (n);");
        let result = try connection.execute(query: query, params: [:])
        print(result)
        
//        let record = connection.nextRecord()
        
        print(record)
    }
    
    func testclearDatabase() throws {
        let connection = try getReadyConnection(lazyFetch: false)
        do {
            _ = try connection.execute(query: "MATCH (n) DETACH DELETE n;")
        }
        catch {
            print("Failed to delete all data from the database.")
        }
    }
    
    func testRetrieveAllInfoInDB() throws {
        
        let connection = try getReadyConnection(lazyFetch: false)
        
        // Fetch the graph.
        let query = "MATCH (n)-[r]->(m) RETURN n, r, m;"
        let columns = try connection.execute(query: "MATCH (n)-[r]->(m) RETURN n, r, m;", params: nil)
//        let columns = try connection.executeWithoutResults(query: query)
        print("Columns: \(columns.isEmpty ? "None": columns.joined(separator: ", "))")
        
        for record in try connection.fetchall() {
            for value in record.values {
                print(value)
            }
        }
        
//        let records = try connection.fetchmany(size: 10)
//
//        for record in try connection.fetchall() {
//            for value in record.values {
//                print(value)
//            }
//        }
//        
//        if let nextRecord = connection.nextRecord() {
//            print(nextRecord.values)
//        }
    }
    
    func testCreateSimpleGraphAndRetrieve() throws {

        // Connect to Memgraph.
        let connection = try getReadyConnection(lazyFetch: true)
        
        // Create simple graph.
        try connection.executeWithoutResults(query: """
            CREATE (p1:Person {name: 'Alice'})-[l1:Likes]->(m:Software {name: 'Memgraph'})
            CREATE (p2:Person {name: 'John'})-[l2:Likes]->(m)
            CREATE (p3:Person {name: 'Peter'})-[l3:Likes]->(x:Software {name: 'Neo4j'});
            """
        )

        // Fetch the graph.
        let columns = try connection.execute(query: "MATCH (n)-[r]->(m) RETURN n, r, m;", params: nil)
        print("Columns: \(columns.joined(separator: ", "))")
        
        for record in try connection.fetchall() {
            for value in record.values {
                switch value {
                case .node(let node):
                    print("\(node)")
                case .relationship(let edge):
                    print("-\(edge)-")
                default:
                    print("\(value)")
                }
            }
        }
        try connection.commit()
    }
    
}
