//
//  MutuallyExclusive.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusive<T>: OperationCondition {
    public static var name: String { return "MutuallyExclusive<\(T.self)>" }
    public static var isMutuallyExclusive: Bool { return true }
    
    public init() {}
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? {
        return nil
    }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        completion(.satisfied)
    }
}
