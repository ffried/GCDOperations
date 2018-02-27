//
//  NoCancelledDependencies.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import struct GCDCoreOperations.ErrorInformation
import protocol GCDCoreOperations.OperationCondition

public extension ErrorInformation.Key {
    public static var cancelledDependencies: ErrorInformation.Key<ContiguousArray<GCDCoreOperations.Operation>> {
        return .init(rawValue: "CancelledDependencies")
    }
}

/**
 A condition that specifies that every dependency must have run.
 If any dependency was cancelled, the target operation will fail.
 */
public struct NoCancelledDependencies: OperationCondition {
    public static let name = "NoCancelledDependencies"
    public static let isMutuallyExclusive = false
    
    public init() {}
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? {
        return nil
    }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        // Verify that all of the dependencies executed.
        let cancelled = ContiguousArray(operation.dependencies.filter { $0.isCancelled })
        
        if !cancelled.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            let info = ErrorInformation(key: .cancelledDependencies, value: cancelled)
            let error = ConditionError(condition: self, errorInformation: info)
            completion(.failed(error))
        } else {
            completion(.satisfied)
        }
    }
}
