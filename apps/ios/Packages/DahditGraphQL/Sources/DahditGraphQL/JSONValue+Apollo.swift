@_spi(Internal) @_spi(Execution) import ApolloAPI
import Foundation

extension JSONValue: CustomScalarType {
    public init(_jsonValue value: ApolloAPI.JSONValue) throws {
        self = try JSONValue(apolloValue: value)
    }

    public var _jsonValue: ApolloAPI.JSONValue {
        switch self {
        case .string(let value):
            value
        case .int(let value):
            value
        case .double(let value):
            value
        case .bool(let value):
            value
        case .array(let values):
            values.map(\._jsonValue) as ApolloAPI.JSONValue
        case .object(let values):
            values.mapValues(\._jsonValue) as ApolloAPI.JSONValue
        case .null:
            NSNull()
        }
    }

    private init(apolloValue value: ApolloAPI.JSONValue) throws {
        try self.init(anyValue: value)
    }

    private init(anyValue value: Any) throws {
        if value is NSNull {
            self = .null
        } else if let value = value as? String {
            self = .string(value)
        } else if let value = value as? NSNumber {
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else if CFNumberIsFloatType(value) {
                self = .double(value.doubleValue)
            } else {
                self = .int(value.intValue)
            }
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? Int {
            self = .int(value)
        } else if let value = value as? Int64 {
            self = .int(Int(value))
        } else if let value = value as? Int32 {
            self = .int(Int(value))
        } else if let value = value as? Double {
            self = .double(value)
        } else if let value = value as? Float {
            self = .double(Double(value))
        } else if let value = value as? ApolloAPI.JSONObject {
            self = .object(try value.mapValues { try JSONValue(anyValue: $0) })
        } else if let value = value as? [ApolloAPI.JSONValue] {
            self = .array(try value.map { try JSONValue(anyValue: $0) })
        } else if let value = value as? NSDictionary {
            var object: [String: JSONValue] = [:]
            for (key, rawValue) in value {
                guard let key = key as? String else {
                    throw JSONDecodingError.couldNotConvert(value: "Non-string JSON object key", to: JSONValue.self)
                }
                object[key] = try JSONValue(anyValue: rawValue)
            }
            self = .object(object)
        } else if let value = value as? NSArray {
            self = .array(try value.map { try JSONValue(anyValue: $0) })
        } else if let value = value as? AnyHashable {
            try self.init(anyValue: value.base)
        } else {
            throw JSONDecodingError.couldNotConvert(value: String(describing: value), to: JSONValue.self)
        }
    }
}
