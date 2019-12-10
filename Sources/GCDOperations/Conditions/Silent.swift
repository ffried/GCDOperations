//
//  Silent.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/**
 A simple condition that causes another condition to not enqueue its dependency.
 This is useful (for example) when you want to verify that you have access to
 the user's location, but you do not want to prompt them for permission if you
 do not already have it.
 */
public struct SilentCondition<Condition: OperationCondition>: OperationCondition {
    public static var name: String { return "Silent<\(Condition.name)>" }
    
    public static var isMutuallyExclusive: Bool { return Condition.isMutuallyExclusive }
    
    private let condition: Condition
    
    public init(condition: Condition) {
        self.condition = condition
    }
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? {
        // We never generate a dependency.
        return nil
    }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        condition.evaluate(for: operation, completion: completion)
    }
}
