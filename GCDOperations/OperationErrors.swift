//
//  OperationErrors.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrfcih. All rights reserved.
//

public struct ConditionError: Error, Equatable {
    public let conditionName: String
    public let information: ErrorInformation?
    
    public init<Condition: OperationCondition>(condition: Condition, errorInformation: ErrorInformation? = nil) {
        self.conditionName = Condition.name
        self.information = errorInformation
    }
    
    public static func ==(lhs: ConditionError, rhs: ConditionError) -> Bool {
        return lhs.conditionName == rhs.conditionName
    }
}

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

    // For Swift 4.0
//    public subscript<T>(_ key: ErrorInformation.Key<T>) -> T? {
//        return value(for: key)
//    }
}

public extension ErrorInformation {
    @available(swift, introduced: 3.1)
    public struct Key<T>: RawRepresentable, Hashable {
        public typealias RawValue = String
        
        public let rawValue: RawValue
        public var hashValue: Int { return rawValue.hashValue }
        
        fileprivate var rawKey: ErrorInformation.RawKey {
            // Allow usages of the same `rawValue` but different Types `T`.
            return "\(rawValue).\(T.self)"
        }
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public static func ==<T>(lhs: Key<T>, rhs: Key<T>) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
}
