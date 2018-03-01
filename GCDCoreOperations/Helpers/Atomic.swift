//
//  Atomic.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class Dispatch.DispatchQueue
import enum Dispatch.DispatchPredicate
import func Dispatch.dispatchPrecondition

/// Atomic wrapper for a value. All access to the stored value will be synced to a serial DispatchQueue.
internal struct Atomic<Value> {
    private let accessQueue = DispatchQueue(label: "net.ffried.Atomic<\(Value.self)>.Lock", attributes: .concurrent)
    
    private var _value: Value
    var value: Value {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        return accessQueue.sync { _value }
    }
    
    init(_ value: Value) { _value = value }
    
    mutating func withValue<T>(do work: (inout Value) throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        return try accessQueue.sync(flags: .barrier) { try work(&_value) }
    }

    mutating func coordinated<OtherValue, T>(with other: inout Atomic<OtherValue>, do work: (inout Value, inout OtherValue) throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .notOnQueue(accessQueue))
        let sameQueue = other.accessQueue === accessQueue
        return try accessQueue.sync(flags: .barrier) {
            if sameQueue { // unlikely
                return try work(&_value, &other._value)
            } else { // likely
                return try other.withValue { try work(&_value, &$0) }
            }
        }
    }
}
