//
//  Atomic.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class Dispatch.DispatchQueue
import enum Dispatch.DispatchPredicate
import func Dispatch.dispatchPrecondition

struct Atomic<Value> {
    private let accessQueue = DispatchQueue(label: "net.ffried.Atomic<\(Value.self)>.Lock")
    
    private var _value: Value
    var value: Value {
        if #available(
           iOS 10.0, iOSApplicationExtension 10.0,
           macOS 10.12, macOSApplicationExtension 10.12,
           tvOS 10.0, tvOSApplicationExtension 10.0,
           watchOS 3.0, watchOSApplicationExtension 3.0, *) {
            dispatchPrecondition(condition: .notOnQueue(accessQueue))
        }
        return accessQueue.sync { _value }
    }
    
    init(_ value: Value) { _value = value }
    
    mutating func withValue<T>(do work: (inout Value) throws -> T) rethrows -> T {
        if #available(
            iOS 10.0, iOSApplicationExtension 10.0,
            macOS 10.12, macOSApplicationExtension 10.12,
            tvOS 10.0, tvOSApplicationExtension 10.0,
            watchOS 3.0, watchOSApplicationExtension 3.0, *) {
            dispatchPrecondition(condition: .notOnQueue(accessQueue))
        }
        return try accessQueue.sync { try work(&_value) }
    }
}
