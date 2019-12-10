//
//  NoFailedDependencies.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import struct GCDCoreOperations.ErrorInformation
import protocol GCDCoreOperations.OperationCondition

extension ErrorInformation.Key {
    public static var failedDependencies: ErrorInformation.Key<ContiguousArray<GCDCoreOperations.Operation>> {
        return .init(rawValue: "FailedDependencies")
    }
}

/**
 A condition that specifies that every dependency must have succeeded.
 If any dependency has errors, the target operation will fail as well.
 */
public struct NoFailedDependencies: OperationCondition {
    public static let name = "NoFailedDependencies"
    public static let isMutuallyExclusive = false
    
    public init() {}
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? {
        return nil
    }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        // Verify that all of the dependencies executed without errors.
        let failed = ContiguousArray(operation.dependencies.filter { !$0.errors.isEmpty })
        
        if !failed.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            let info = ErrorInformation(key: .failedDependencies, value: failed)
            let error = ConditionError(condition: self, errorInformation: info)
            completion(.failed(error))
        } else {
            completion(.satisfied)
        }
    }
}
