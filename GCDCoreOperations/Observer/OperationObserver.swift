//
//  OperationObserver.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public protocol OperationObserver {
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(_ operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(_ operation: Operation, didProduce newOperation: Operation)
    
    /// Invoked when an `Operation` finishes, along with whether it was cancelled and any errors produced during execution.
    func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: [Error])
}

// MARK: - Helper Extension
internal extension Sequence where Iterator.Element == OperationObserver {
    func operationDidStart(_ operation: Operation) {
        forEach { $0.operationDidStart(operation) }
    }
    
    func operation(_ operation: Operation, didProduce newOperation: Operation) {
        forEach { $0.operation(operation, didProduce: newOperation) }
    }
    
    func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: [Error]) {
        forEach { $0.operationDidFinish(operation, wasCancelled: cancelled, errors: errors) }
    }
}
