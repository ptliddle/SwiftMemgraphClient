// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Cmgclient

class SwiftMemgraphClient {
    
    init() { }
    
    var memgraphClientVersion: String {
        guard let c_version = Cmgclient.mg_client_version() else { return "n/a" }
        let version = String(cString: c_version)
        return version
    }
    
    func connect() throws {
        let connectParams = ConnectParams(host: "localhost")
        let mgclient = try Connection.connect(params: connectParams)
    }
}
