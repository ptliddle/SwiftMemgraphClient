//
//  CValues.swift
//  This class defines all the values that the underliying C library (mgclient) uses, in a Swift format. Note this should define pure C library types in Swift, it shouldn't add methods, those should be added as
//  extensions in CTypeConversion+Extensions to seperate the C structure definitions from data handling and conversion.
//
//  TODO:
//  It maybe possible to remove this file by altering how the C library (mgclient) this Swift library wraps is built to export the underlying C values.
//  At the moment mgvalue.h is in a different directory to the mgclient.h which it references during build time so trying to export mgvalue.h causes
//  the building of the C libary to fail. However it should be possible to create a virtual file system during build so that all the headers appear in the
//  same directory and can reference each other. It should then be possible to add value.h as one of the exported headers.
//
//  SEE: Section "Importing SQLite into Swift" at https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html specifcally the part referencing VFS (The virtual filesystem)
//
//  Created by Peter Liddle on 8/4/24.
//



import Foundation
import Cmgclient

//typedef struct mg_date {
//  int64_t days;
//} mg_date;
typealias mg_date = Int64

// Below we redifine in Swift some of the types used in C that aren't explicitly exported. This saves us from having to export the definitions
// C and Swift lay out structs in memory the same so assuming we use compatible types and ordering is the same these short be compatible

//typedef struct mg_time {
//  int64_t nanoseconds;
//  int64_t tz_offset_seconds;
//} mg_time;
struct MgTime {
    var nanoseconds: Int64
    var tz_offset_seconds: Int64
}
typealias mg_time = MgTime

//typedef struct mg_local_time {
//  int64_t nanoseconds;
//} mg_local_time;
typealias mg_local_time = Int64

//typedef struct mg_date_time {
//  int64_t seconds;
//  int64_t nanoseconds;
//  int64_t tz_offset_minutes;
//} mg_date_time;
typealias mg_date_time = Int64

//typedef struct mg_date_time_zone_id {
//  int64_t seconds;
//  int64_t nanoseconds;
//  int64_t tz_id;
//} mg_date_time_zone_id;
//typealias mg_date_time_zone_id
struct MgDateTimeZoneId {
    var seconds: Int64
    var nanoseconds: Int64
    var tz_id: Int64
}
typealias mg_date_time_zone_id = MgDateTimeZoneId

//typedef struct mg_local_date_time {
//  int64_t seconds;
//  int64_t nanoseconds;
//} mg_local_date_time;
struct MgLocalDateTime {
    var seconds: Int64
    var nanoseconds: Int64
}
typealias mg_local_date_time = MgLocalDateTime

//typedef struct mg_duration {
//  int64_t months;
//  int64_t days;
//  int64_t seconds;
//  int64_t nanoseconds;
//} mg_duration;
struct MgDuration {
    var months: Int64
    var days: Int64
    var seconds: Int64
    var nanoseconds: Int64
}
typealias mg_duration = MgDuration

//typedef struct mg_list {
//  uint32_t size;
//  uint32_t capacity;
//  mg_value **elements;
//} mg_list;
struct c_mg_list {
    var size: UInt32
    var capacity: UInt32
    var elements: UnsafePointer<UnsafePointer<c_mg_value>>
}
typealias mg_list = c_mg_list

//typedef struct mg_string {
//  uint32_t size;
//  char *data;
//} mg_string;
struct c_mg_string {
    var size: UInt32
    var data: UnsafePointer<CChar>
}
typealias mg_string = c_mg_string

//typedef struct mg_map {
//  uint32_t size;
//  uint32_t capacity;
//  mg_string **keys;
//  mg_value **values;
//} mg_map;
// Swift struct to represent mg_map
struct c_mg_map: HasOpagueCPointer {
    
    var size: UInt32
    var capacity: UInt32
    var keys: UnsafePointer<UnsafePointer<c_mg_string>?>
    var values: UnsafePointer<UnsafePointer<c_mg_value>?>
}
typealias mg_map = c_mg_map

// Representation of parameter value used in query.
#warning("QueryParam has not yet been utilized or tested, needs work")
public enum QueryParam {
    case null
    case bool(Bool)
    case int(Int64)
    case float(Double)
    case string(String)
    case date(Date)
    case localTime(Date)
    case localDateTime(Date)
    case duration(TimeInterval)
    case list([QueryParam])
    case map([String: QueryParam])
    
    func toCMgValue() -> UnsafeMutablePointer<mg_value_type> {
        switch self {
        case .null:
            return UnsafeMutablePointer(mg_value_make_null())
        case .bool(let value):
            return UnsafeMutablePointer(mg_value_make_bool(value ? 1 : 0))
        case .int(let value):
            return UnsafeMutablePointer(mg_value_make_integer(value))
        case .float(let value):
            return UnsafeMutablePointer(mg_value_make_float(value))
        case .string(let value):
            return UnsafeMutablePointer(mg_value_make_string(value.asCStr))
        case .date(let value):
            let oPointer = OpaquePointer(SwiftToCConverter.dateToMgDate(value))
            return UnsafeMutablePointer(mg_value_make_date(oPointer))
        case .localTime(let value):
            let oPointer = OpaquePointer(SwiftToCConverter.timeToMgLocalTime(value))
            return UnsafeMutablePointer(mg_value_make_local_time(oPointer))
        case .localDateTime(let value):
            let oPointer = OpaquePointer(SwiftToCConverter.dateTimeToMgLocalDateTime(value))
            return UnsafeMutablePointer(mg_value_make_local_date_time(oPointer))
        case .duration(let value):
            let oPointer = OpaquePointer(SwiftToCConverter.durationToMgDuration(value))
            return UnsafeMutablePointer(mg_value_make_duration(oPointer))
        case .list(let value):
            fatalError("Convert list not yet implemented")
//            let oPointer = OpaquePointer(mg_value_make_list(vectorToMgList(value)))
        case .map(let value):
            fatalError("Convert list not yet implemented")
//            let oPointer = OpaquePointer(mg_value_make_map(hashMapToMgMap(value)))
        default:
            break
        }
    }
}

//typedef struct mg_node {
//  int64_t id;
//  uint32_t label_count;
//  mg_string **labels;
//  mg_map *properties;
//} mg_node;
struct c_mg_node {
    var id: Int64
    var labelCount: UInt32
    var labels: UnsafeMutablePointer<UnsafeMutablePointer<mg_string>?>
    var properties: UnsafeMutablePointer<mg_map>?
    
//    var labelsAsSwiftStrings: [String] {
//        return mg_string.mg_stringCArrayToSwiftArray(mg_stringCArrayPointer: OpaquePointer(self.labels), itemCount: Int(labelCount))
//    }
}
typealias mg_node = c_mg_node


//typedef struct mg_relationship {
//  int64_t id;
//  int64_t start_id;
//  int64_t end_id;
//  mg_string *type;
//  mg_map *properties;
//} mg_relationship;
struct c_mg_relationship {
    var id: Int64
    var start_id: Int64
    var end_id: Int64
    var type: UnsafePointer<mg_string>
    var properties: UnsafePointer<mg_map>
}
typealias mg_relationship = c_mg_relationship


//struct mg_value {
//  enum mg_value_type type;
//  union {
//    int bool_v;
//    int64_t integer_v;
//    double float_v;
//    mg_string *string_v;
//    mg_list *list_v;
//    mg_map *map_v;
//    mg_node *node_v;
//    mg_relationship *relationship_v;
//    mg_unbound_relationship *unbound_relationship_v;
//    mg_path *path_v;
//    mg_date *date_v;
//    mg_time *time_v;
//    mg_local_time *local_time_v;
//    mg_date_time *date_time_v;
//    mg_date_time_zone_id *date_time_zone_id_v;
//    mg_local_date_time *local_date_time_v;
//    mg_duration *duration_v;
//    mg_point_2d *point_2d_v;
//    mg_point_3d *point_3d_v;
//  };
//};
public struct c_mg_value {
    enum c_mg_value_type: Int {
        case null = 0
        case bool = 1
        case integer = 2
        case float = 3
        case string = 4
        case list = 5
        case map = 6
        case node = 7
        case relationship = 8
        case unboundRelationship = 9
        case path = 10
        case date = 11
        case time = 12
        case localTime = 13
        case dateTime = 14
        case dateTimeZoneId = 15
        case localDateTime = 16
        case duration = 17
        case point2D = 18
        case point3D = 19
        case unknown = 20
    }
    
    var type: c_mg_value_type
    var value: UnsafeRawPointer
}
typealias mg_value = c_mg_value
