//
//  SwiftToCConverter.swift
//  This file contains methods for converting from Swift datatypes to C datatypes that can be sent to the mgclient C library
//
//  Created by Peter Liddle on 8/6/24.
//

import Foundation
import Cmgclient
//
//  Created by Peter Liddle on 8/8/24.
//

import Foundation


/// A struct is used to group these functions but they are all static so no instance of the structure is needed to utilize them
struct SwiftToCConverter {
    
    static func dictionaryToCMgMap(properties: [String: Value]) -> OpaquePointer? {
        
        let noOfProps: UInt32 = UInt32(properties.count)
        
        let cPropMapOp = mg_map_make_empty(noOfProps)
        for (key, value) in properties {
            let cValue = value.asCMgValue
            mg_map_insert(cPropMapOp, key.asCStr, cValue)
        }
        
        return cPropMapOp
    }
    
    static func dateToMgDate(_ date: Date) -> UnsafeMutablePointer<mg_date> {
        // Convert Date to mg_date
        // Implementation depends on the specific C API
        
        print("convert date")
        
        // Get the number of seconds since the Unix epoch
        let secondsSinceEpoch = date.timeIntervalSince1970
        
        // Convert seconds to nanoseconds
        var nanosecondsSinceEpoch = Int64(secondsSinceEpoch) * 1_000_000_000
        
        return withUnsafeMutablePointer(to: &nanosecondsSinceEpoch) { $0 }
    }

    static func timeToMgLocalTime(_ time: Date) -> UnsafeMutablePointer<mg_local_time> {
        // Convert Date to mg_local_time
        // Implementation depends on the specific C API
        print("convert local time")
        // Get the number of seconds since the Unix epoch
        let secondsSinceEpoch = time.timeIntervalSince1970
        
        // Convert seconds to nanoseconds
        var nanosecondsSinceEpoch = Int64(secondsSinceEpoch) * 1_000_000_000
        
        // Return the nanoseconds as mg_local_time
        return withUnsafeMutablePointer(to: &nanosecondsSinceEpoch) { $0 }
    }

    static func dateTimeToMgLocalDateTime(_ dateTime: Date) -> UnsafeMutablePointer<mg_local_date_time> {
        // Convert Date to mg_local_date_time
        // Implementation depends on the specific C API
        print("convert local date time")
        
        // Get the number of seconds since the Unix epoch
        let secondsSinceEpoch = dateTime.timeIntervalSince1970
        
        // Convert seconds to nanoseconds
        let nanosecondsSinceEpoch = Int64(secondsSinceEpoch) * 1_000_000_000
        
        var localDateTime = MgLocalDateTime(seconds: Int64(dateTime.timeIntervalSince1970), nanoseconds: nanosecondsSinceEpoch)
        
        return withUnsafeMutablePointer(to: &localDateTime) { $0 }
    }

    static func durationToMgDuration(_ duration: TimeInterval) -> UnsafeMutablePointer<mg_duration> {
        // Convert TimeInterval to mg_duration
        // Implementation depends on the specific C API
        
        let calendar = Calendar.current
        let referenceDate = Date.timeIntervalSinceReferenceDate
        let durationDate = Date(timeIntervalSince1970: duration)
        
        // Calculate the difference in components
        let components = calendar.dateComponents([.month, .day, .second, .nanosecond], from: durationDate)
        
        // Extract the components
        let months = Int64(components.month ?? 0)
        let days = Int64(components.day ?? 0)
        let seconds = Int64(components.second ?? 0)
        let nanoseconds = Int64(components.nanosecond ?? 0)
        
        var swiftDuration = MgDuration(months: months, days: days, seconds: seconds, nanoseconds: nanoseconds)
        
        return withUnsafeMutablePointer(to: &swiftDuration) { $0 }
    }
}
