//
//  OperationErrors.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public struct ErrorInformation {
    fileprivate typealias RawKey = String
    
    private var infoDict: Dictionary<RawKey, Any> = [:]
    
    public var isEmpty: Bool { return infoDict.isEmpty }
    
    public init() {}
    
    public init<T>(key: Key<T>, value: T) {
        set(value: value, for: key)
    }
    
    public mutating func set<T>(value: T, for key: Key<T>) {
        infoDict[key.rawKey] = value
    }
    
    public func value<T>(for key: Key<T>) -> T? {
        return infoDict[key.rawKey] as? T
    }

    public subscript<T>(_ key: Key<T>) -> T? {
        return value(for: key)
    }
}

public extension ErrorInformation {
    public struct Key<T>: RawRepresentable, Hashable {
        public typealias RawValue = String
        
        public let rawValue: RawValue
        public var hashValue: Int { return rawValue.hashValue }
        
        fileprivate var rawKey: ErrorInformation.RawKey {
            // Allow usages of the same `rawValue` but different Types `T`.
            // E.g. `Key<String>(rawValue: "abc")` and `Key<Int>(rawValue: "abc")`
            return "\(rawValue).\(T.self)"
        }
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public static func ==(lhs: Key<T>, rhs: Key<T>) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
}

