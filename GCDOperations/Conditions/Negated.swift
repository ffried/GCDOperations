//
//  Negated.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import struct GCDCoreOperations.ErrorInformation
import protocol GCDCoreOperations.OperationCondition

public extension ErrorInformation.Key {
    public static var negatedCondition: ErrorInformation.Key<OperationCondition> {
        return .init(rawValue: "NegatedCondition")
    }
}

/**
 A simple condition that negates the evaluation of another condition.
 This is useful (for example) if you want to only execute an operation if the
 network is NOT reachable.
 */
public struct NegatedCondition<Condition: OperationCondition>: OperationCondition {
    public static var name: String {
        return "Not<\(Condition.name)>"
    }
    
    public static var isMutuallyExclusive: Bool {
        return Condition.isMutuallyExclusive
    }
    
    private let condition: Condition
    
    public init(condition: Condition) {
        self.condition = condition
    }
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? {
        return condition.dependency(for: operation)
    }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        condition.evaluate(for: operation) {
            switch $0 {
            case .failed(_):
                // If the composed condition failed, then this one succeeded.
                completion(.satisfied)
            case .satisfied:
                // If the composed condition succeeded, then this one failed.
                let info = ErrorInformation(key: .negatedCondition, value: self.condition)
                let error = ConditionError(condition: self, errorInformation: info)
                
                completion(.failed(error))
            }
        }
    }
}
