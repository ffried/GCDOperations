//
//  OperationObserver.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public protocol OperationObserver {
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(_ operation: Operation)
    
    /// Invoked immediately after the first time the `Operation`'s `cancel()` method is called
    func operationDidCancel(_ operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(_ operation: Operation, didProduce newOperation: Operation)
    
    /**
     Invoked as an `Operation` finishes, along with any errors produced during
     execution (or readiness evaluation).
     */
    func operationDidFinish(_ operation: Operation, errors: [Error])
}

internal extension Sequence where Iterator.Element == OperationObserver {
    func operationDidStart(_ operation: Operation) {
        forEach { $0.operationDidStart(operation) }
    }
    
    func operationDidCancel(_ operation: Operation) {
        forEach { $0.operationDidCancel(operation) }
    }
    
    func operation(_ operation: Operation, didProduce newOperation: Operation) {
        forEach { $0.operation(operation, didProduce: newOperation) }
    }
    
    func operationDidFinish(_ operation: Operation, errors: [Error]) {
        forEach { $0.operationDidFinish(operation, errors: errors) }
    }
}
