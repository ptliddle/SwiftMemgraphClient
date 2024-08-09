//
//  Connection.swift
//
//
//  Created by Peter Liddle on 8/4/24.
//

import Foundation
import Cmgclient

// Parameters for connecting to database.
public struct ConnectParams {
    public var port: UInt16
    public var host: String?
    public var address: String?
    public var username: String?
    public var password: String?
    public var clientName: String
    public var sslmode: SSLMode
    public var sslcert: String?
    public var sslkey: String?
    public var trustCallback: ((String, String, String, String) -> Int32)?
    public var lazy: Bool
    public var autocommit: Bool

    public init(port: UInt16 = 7687,
                host: String? = nil,
                address: String? = nil,
                username: String? = nil,
                password: String? = nil,
                clientName: String = "rsmgclient/0.1",
                sslmode: SSLMode = .disable,
                sslcert: String? = nil,
                sslkey: String? = nil,
                trustCallback: ((String, String, String, String) -> Int32)? = nil,
                lazy: Bool = true,
                autocommit: Bool = false) {
        self.port = port
        self.host = host
        self.address = address
        self.username = username
        self.password = password
        self.clientName = clientName
        self.sslmode = sslmode
        self.sslcert = sslcert
        self.sslkey = sslkey
        self.trustCallback = trustCallback
        self.lazy = lazy
        self.autocommit = autocommit
    }
}

// Determines whether a secure SSL TCP/IP connection will be negotiated with the server.
public enum SSLMode: UInt32 {
    case disable = 0
    case require = 1
    
    var asCmg_sslmode: mg_sslmode {
        return mg_sslmode.init(self.rawValue)
    }
}

// Representation of current connection status.
public enum ConnectionStatus: UInt8 {
    case ready
    case inTransaction
    case executing
    case fetching
    case closed
    case bad
}

// Define the C function pointer type
typealias TrustCallbackType = @convention(c) (UnsafePointer<CChar>?,
                                              UnsafePointer<CChar>?,
                                              UnsafePointer<CChar>?,
                                              UnsafePointer<CChar>?,
                                              UnsafeMutableRawPointer?) -> Int

// Encapsulates a database connection.
open class Connection {
    private var mgSession: OpaquePointer?
    
    public private(set) var lazy: Bool
    public private(set) var autocommit: Bool
    public var arraysize: UInt32
    public private(set) var status: ConnectionStatus
    public private(set) var summary: [String: Value]?
    
    private var resultsIter: IndexingIterator<[Record]>?

    private init(mgSession: OpaquePointer?,
                lazy: Bool,
                autocommit: Bool,
                status: ConnectionStatus,
                resultsIter: IndexingIterator<[Record]>?,
                arraysize: UInt32,
                summary: [String: Value]?) {
        self.mgSession = mgSession
        self.lazy = lazy
        self.autocommit = autocommit
        self.status = status
        self.resultsIter = resultsIter
        self.arraysize = arraysize
        self.summary = summary
    }

    deinit {
        if let mgSession = mgSession {
            mg_session_destroy(mgSession)
        }
        Connection.CMgFinalize()
    }

    private static func CmgInit() {
        mg_init()
    }

    private static func CMgFinalize() {
        mg_finalize()
    }

    public func setLazy(_ lazy: Bool) {
        guard status == .ready else {
            fatalError("Can't set lazy while not in ready status")
        }
        self.lazy = lazy
    }

    public func setAutocommit(_ autocommit: Bool) {
        guard status == .ready else {
            fatalError("Can't set autocommit while not in ready status")
        }
        self.autocommit = autocommit
    }
    
    public static func connect(params: ConnectParams) throws -> Connection {
        
        Connection.CmgInit()
        
        let mgSessionParams = mg_session_params_make()
        var trustCallbackPtr: UnsafeMutableRawPointer?

        if let host = params.host {
            mg_session_params_set_host(mgSessionParams, strToCStr(host))
        }
        
        mg_session_params_set_port(mgSessionParams, params.port)
        
        if let address = params.address {
            mg_session_params_set_address(mgSessionParams, strToCStr(address))
        }
        
        if let username = params.username {
            mg_session_params_set_username(mgSessionParams, strToCStr(username))
        }
        
        if let password = params.password {
            mg_session_params_set_password(mgSessionParams, strToCStr(password))
        }
        
        mg_session_params_set_user_agent(mgSessionParams, strToCStr(params.clientName))
        mg_session_params_set_sslmode(mgSessionParams, params.sslmode.asCmg_sslmode)
        
        if let sslcert = params.sslcert {
            mg_session_params_set_sslcert(mgSessionParams, strToCStr(sslcert))
        }
        
        if let sslkey = params.sslkey {
            mg_session_params_set_sslkey(mgSessionParams, strToCStr(sslkey))
        }
        
        if let trustCallback = params.trustCallback {
            fatalError("Need to implement trust callback capability")
//            trustCallbackPtr = Unmanaged.passRetained(trustCallback as AnyObject).toOpaque()
//            mg_session_params_set_trust_data(mgSessionParams, trustCallbackPtr)
//            let trustCallbackWrapperPointer: TrustCallbackType = trustCallbackWrapper(host:ipAddress:keyType:fingerprint:funRaw:)
//            mg_session_params_set_trust_callback(mgSessionParams, trustCallbackWrapperPointer)
        }

        var mgSession: OpaquePointer?
        
        let status = mg_connect(mgSessionParams, &mgSession)
        
        mg_session_params_destroy(mgSessionParams)
        
        if let trustCallbackPtr = trustCallbackPtr {
            Unmanaged<AnyObject>.fromOpaque(trustCallbackPtr).release()
        }

        if status != 0 {
            throw MgError(message: MgError.readMgSessionErrorMessage(mgSession))
        }

        return Connection(mgSession: mgSession,
                          lazy: params.lazy,
                          autocommit: params.autocommit,
                          status: .ready,
                          resultsIter: nil,
                          arraysize: 1,
                          summary: nil)
    }
    
    
       /// Fully Executes provided query but doesn't return any results even if they exist.
    public func executeWithoutResults(query: String) throws {
           let cQuery = query.cString(using: .utf8)!
           
           let runStatus = mg_session_run(self.mgSession, cQuery, nil, nil, nil, nil)
           if runStatus == 0 {
               self.status = .executing
           } else {
               self.status = .bad
               throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
           }
           
           let pullStatus = mg_session_pull(self.mgSession, nil)
           if pullStatus == 0 {
               self.status = .fetching
           } else {
               self.status = .bad
               throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
           }
           
           while true {
               var result: OpaquePointer? = nil
               let fetchStatus = mg_session_fetch(self.mgSession, &result)
               switch fetchStatus {
               case 1:
                   continue
               case 0:
                   self.status = .ready
                   return
               default:
                   self.status = .bad
                   throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
               }
           }
       }

    
    /// Executes provided query using parameters (if provided) and returns names of columns.
    ///
    /// After execution records need to get fetched using fetch methods. Connection needs to be in
    /// status `Ready` or `InTransaction`. Error is returned if connection is not ready, query is
    /// invalid or there was an error in communication with server.
    ///
    /// If connection is not lazy will also fetch and store all records. If connection has
    /// autocommit set to false and is not in a transaction will also start a transaction.
    public func execute(query: String, params: [String: QueryParam]? = nil) throws -> [String] {
        switch self.status {
        case .ready, .inTransaction:
            break
        case .executing:
            throw MgError("Can't call execute while already executing")
        case .fetching:
            throw MgError("Can't call execute while fetching")
        case .closed:
            throw MgError("Can't call execute while connection is closed")
        case .bad:
            throw MgError("Can't call execute while connection is bad")
        }
        
        if !self.autocommit && self.status == .ready {
            do {
                try self.executeWithoutResults(query: "BEGIN")
                self.status = .inTransaction
            } catch {
                throw error
            }
        }
        
        self.summary = nil
        
        let cQuery = query.cString(using: .utf8)!
        let mgParams = params != nil ? mg_map.from(params!) : nil
        let opagueColumnPointer: UnsafeMutablePointer<OpaquePointer?>? = nil
        
        let status = mg_session_run(self.mgSession, cQuery, OpaquePointer(mgParams), nil, opagueColumnPointer, nil)
        
        if status != 0 {
            self.status = .bad
            throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
        }
        
        self.status = .executing
        
        if !self.lazy {
            do {
                let results = try self.pullAndFetchAll()
                self.resultsIter = results.makeIterator()
            } catch {
                self.status = .bad
                throw error
            }
        }
        
        let columns: [String]
        if let mgListPointer = opagueColumnPointer?.pointee {
            columns = CToSwiftConverter.mgListCArrayToMgListSwiftArray(mgListCArrayPointer: mgListPointer).compactMap({ rawValue in
                if let value = rawValue.asValue, case let Value.string(stringValue) = value {
                    return stringValue
                }
                else {
                    return nil
                }
            })
        }
        else {
            columns = []
        }
        
        return columns
    }

/// Returns next row of query results or None if there is no more data available.
    ///
    /// Returns error if connection is not in `Executing` status or if there was an error while
    /// pulling record from database.
    func fetchone() throws -> Record? {
        switch self.status {
        case .ready:
            throw MgError("Can't call fetchone while ready")
        case .inTransaction:
            throw MgError("Can't call fetchone while in transaction")
        case .executing, .fetching:
            break
        case .closed:
            throw MgError("Can't call fetchone if connection is closed")
        case .bad:
            throw MgError("Can't call fetchone if connection is bad")
        }
        
        if self.lazy {
           
            if self.status == .executing {
                do {
                    try self.pull(1)
                    // The status update is already done in the pull.
                } 
                catch {
                    self.status = .bad
                    throw error
                }
            }
            
            let fetchResult = try self.fetch()
           
            if let record = fetchResult.0 {
                if let hasMore = fetchResult.1, hasMore {
                    self.status = .executing
                }
                return record
            } 
            else {
                self.status = self.autocommit ? .ready : .inTransaction
                return nil
            }
        } 
        else {
            if let record = self.nextRecord() {
                return record
            } 
            else {
                self.status = self.autocommit ? .ready : .inTransaction
                return nil
            }
        }
    }

    func nextRecord() -> Record? {
        return self.resultsIter?.next() ?? nil
    }
    
    /// Returns next rows of query results.
    ///
    /// The number of rows to fetch is specified either by `size` or `arraysize` attribute,
    /// `size`(if provided) overrides `arraysize`.
    ///
    /// Returns error if connection is not in `Executing` status or if there was an error while
    /// pulling record from database.
    func fetchmany(size: UInt32?) throws -> [Record] {
        let size = size ?? self.arraysize
        
        var vec = [Record]()
        for _ in 0..<size {
            do {
                if let record = try self.fetchone() {
                    vec.append(record)
                } else {
                    break
                }
            } catch {
                throw error
            }
        }
        
        return vec
    }
    
    /// Returns all(remaining) rows of query results.
    ///
    /// Returns error if connection is not in `Executing` status or if there was an error while
    /// pulling record from database.
    func fetchall() throws -> [Record] {
        var vec = [Record]()
        while true {
            do {
                if let record = try self.fetchone() {
                    vec.append(record)
                } else {
                    break
                }
            } catch {
                throw error
            }
        }
        return vec
    }
    
    /// Pulls the specified number of records from the database.
    ///
    /// Returns error if connection is not in `Executing` status or if there was an error while
    /// pulling record from database.
    func pull(_ n: Int64) throws {
        switch self.status {
        case .ready:
            throw MgError("Can't call pull while ready")
        case .inTransaction:
            throw MgError("Can't call pull while in transaction")
        case .executing:
            break
        case .fetching:
            throw MgError("Can't call pull while fetching")
        case .closed:
            throw MgError("Can't call pull if connection is closed")
        case .bad:
            throw MgError("Can't call pull if connection is bad")
        }
        
        let pullStatus: Int32
        if n == 0 {
            pullStatus = mg_session_pull(self.mgSession, nil)
        } else {
            let mgMap = mg_map_make_empty(1)
            guard mgMap != nil else {
                self.status = .bad
                throw MgError("Unable to make pull map.")
            }
            
            let mgInt = mg_value_make_integer(n)
            guard mgInt != nil else {
                self.status = .bad
                mg_map_destroy(mgMap)
                throw MgError("Unable to make pull map integer value.")
            }
            
            if mg_map_insert(mgMap, "n".cString(using: .utf8), mgInt) != 0 {
                self.status = .bad
                mg_map_destroy(mgMap)
                mg_value_destroy(mgInt)
                throw MgError("Unable to insert into pull map.")
            }
            
            pullStatus = mg_session_pull(self.mgSession, mgMap)
            mg_map_destroy(mgMap)
        }
        
        if pullStatus == 0 {
            self.status = .fetching
        } else {
            self.status = .bad
            throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
        }
    }

    
       /// Maybe returns Record and has_more flag
    func fetch() throws -> (Record?, Bool?) {
        
           switch self.status {
           case .ready:
               throw MgError("Can't call fetch while ready")
           case .inTransaction:
               throw MgError("Can't call fetch while in transaction")
           case .executing:
               throw MgError("Can't call fetch while executing")
           case .fetching:
               break
           case .closed:
               throw MgError("Can't call fetch if connection is closed")
           case .bad:
               throw MgError("Can't call fetch if connection is bad")
           }
           
           var mgResult: OpaquePointer? = nil
           let fetchStatus = mg_session_fetch(self.mgSession, &mgResult)
           
           switch fetchStatus {
           case 1:
               let row = mg_result_row(mgResult)
               let rowPointer = UnsafePointer<mg_list>(row)
               let rowValues = mg_list.convertToValues(rowPointer) ?? []
               return (Record(values: rowValues), nil)
           case 0:
               let mgSummary = mg_result_summary(mgResult)
               let mgHasMore = mg_map_at(mgSummary, "has_more".cString(using: .utf8))
               let hasMore = mg_value_bool(mgHasMore) != 0
//               self.summary = mg_map_to_hash_map(mgSummary)

               self.summary = mgSummary != nil ? CToSwiftConverter.mgMapToStringCMgValueSwiftDictionary(mgMapCPointer: mgSummary!) : [:]
            
               return (nil, hasMore)
           default:
               throw MgError(MgError.readMgSessionErrorMessage(self.mgSession))
           }
       }
       
       func pullAndFetchAll() throws -> [Record] {
           var res = [Record]()
           do {
               try self.pull(0)
               while true {
                   let x = try self.fetch()
                   if let record = x.0 {
                       res.append(record)
                   } else {
                       break
                   }
               }
           } catch {
               throw error
           }
           return res
       }
       
       /// Commit any pending transaction to the database.
       ///
       /// Returns error if there are queries that didn't finish executing.
       ///
       /// If `autocommit` is set to true or there is no pending transaction this method does nothing.
       func commit() throws {
           switch self.status {
           case .ready, .inTransaction:
               break
           case .executing:
               throw MgError("Can't commit while executing")
           case .fetching:
               throw MgError("Can't commit while fetching")
           case .closed:
               throw MgError("Can't commit while connection is closed")
           case .bad:
               throw MgError("Can't commit while connection is bad")
           }
           
           if self.autocommit || self.status != .inTransaction {
               return
           }
           
           do {
               try self.executeWithoutResults(query: "COMMIT")
               self.status = .ready
           } catch {
               throw error
           }
       }
    
    /// Rollback any pending transaction to the database.
   ///
   /// Returns error if there are queries that didn't finish executing.
   ///
   /// If `autocommit` is set to true or there is no pending transaction this method does nothing.
   func rollback() throws {
       switch self.status {
       case .ready:
           throw MgError("Can't rollback while not in transaction")
       case .inTransaction:
           break
       case .executing:
           throw MgError("Can't rollback while executing")
       case .fetching:
           throw MgError("Can't rollback while fetching")
       case .closed:
           throw MgError("Can't rollback while connection is closed")
       case .bad:
           throw MgError("Can't rollback while connection is bad")
       }
       
       if self.autocommit {
           return
       }
       
       do {
           try self.executeWithoutResults(query: "ROLLBACK")
           self.status = .ready
       } catch {
           throw error
       }
   }
   
   /// Closes the connection.
   ///
   /// The connection will be unusable from this point forward. Any operation on connection will
   /// return error.
   func close() {
       switch self.status {
       case .ready, .inTransaction:
           self.status = .closed
       case .executing:
           fatalError("Can't close while executing")
       case .fetching:
           fatalError("Can't close while fetching")
       case .closed:
           break
       case .bad:
           fatalError("Can't close a bad connection")
       }
   }
    
//    func parseColumns(mg_list: mg_list) -> [String] {
//        return mg_list.asSwiftArray().compactMap({ if case let Value.string(string) = $0 { return string } else { return nil } })
//    }
    
    // Trust callback wrapper function
    func trustCallbackWrapper(
        host: UnsafePointer<CChar>?,
        ipAddress: UnsafePointer<CChar>?,
        keyType: UnsafePointer<CChar>?,
        fingerprint: UnsafePointer<CChar>?,
        funRaw: UnsafeMutableRawPointer?
    ) -> CInt {
        let fun = funRaw?.assumingMemoryBound(to: ((String, String, String, String) -> Int32).self).pointee

        if let fun = fun {
            let hostString = String(cString: host!)
            let ipAddressString = String(cString: ipAddress!)
            let keyTypeString = String(cString: keyType!)
            let fingerprintString = String(cString: fingerprint!)
            
            return fun(hostString, ipAddressString, keyTypeString, fingerprintString)
        }
        return 0
    }

    

    // Other methods like execute, fetchone, fetchmany, fetchall, commit, rollback, close, etc.
    // would be implemented similarly, translating Rust idioms to Swift.



    private static func strToCStr(_ str: String) -> UnsafePointer<CChar> {
        return (str as NSString).utf8String!
    }



    private static func trustCallbackWrapper(host: UnsafePointer<CChar>?,
                                             ipAddress: UnsafePointer<CChar>?,
                                             keyType: UnsafePointer<CChar>?,
                                             fingerprint: UnsafePointer<CChar>?,
                                             funRaw: UnsafeMutableRawPointer?) -> Int32 {
        let fun = Unmanaged<AnyObject>.fromOpaque(funRaw!).takeUnretainedValue() as! (String, String, String, String) -> Int32
        return fun(String(host, nil),
                   String(ipAddress, nil),
                   String(keyType, nil),
                   String(fingerprint, nil))
    }
}
 
extension MgError {
    static func readMgSessionErrorMessage(_ mgSession: OpaquePointer?) -> String {
        let cErrorMessage = mg_session_error(mgSession)
        return String(cString: cErrorMessage!)
    }
}
