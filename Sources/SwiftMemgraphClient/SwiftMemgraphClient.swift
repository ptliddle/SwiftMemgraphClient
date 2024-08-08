// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Cmgclient

class SwiftMemgraphClient {
    
    init() { }
    
    var memgraphClientVersion: String {
        guard let c_version = Cmgclient.mg_client_version() else { return "Failed to get version" }
        let version = String(cString: c_version)
        return version
    }
}
