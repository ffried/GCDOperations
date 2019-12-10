//
//  Atomic.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class Dispatch.DispatchQueue
import func Dispatch.dispatchPrecondition

/// Atomic wrapper for a value. All access to the stored value will be synced.
@propertyWrapper
internal final class Atomic<Value> {
    private let accessQueue = DispatchQueue(label: "net.ffried.Atomic<\(Value.self)>.Lock", attributes: .concurrent)
    
    private var _wrappedValue: Value
    var wrappedValue: Value {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        return accessQueue.sync { _wrappedValue }
    }
    
    init(wrappedValue: Value) { _wrappedValue = wrappedValue }
    
    func withValue<T>(do work: (inout Value) throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        return try accessQueue.sync(flags: .barrier) { try work(&_wrappedValue) }
    }

    func coordinated<OtherValue, T>(with other: Atomic<OtherValue>, do work: (inout Value, inout OtherValue) throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        return try accessQueue.sync(flags: .barrier) {
            if other.accessQueue === accessQueue { // unlikely
                return try work(&_wrappedValue, &other._wrappedValue)
            } else { // likely
                return try other.withValue { try work(&_wrappedValue, &$0) }
            }
        }
    }
}
