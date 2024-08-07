import XCTest
@testable import SwiftMemgraphClient
import Cmgclient

final class SwiftMemgraphClientTests: XCTestCase {
    
    func testmgclientVersion() throws {
        let version = SwiftMemgraphClient().memgraphClientVersion
        print("mgclient version is \(version)")
    }
    
}
