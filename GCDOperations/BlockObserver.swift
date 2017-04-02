//
//  BlockObserver.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrfcih. All rights reserved.
//

public struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    fileprivate let startHandler: ((Operation) -> Void)?
    fileprivate let cancelHandler: ((Operation) -> Void)?
    fileprivate let produceHandler: ((Operation, Operation) -> Void)?
    fileprivate let finishHandler: ((Operation, [Error]) -> Void)?
    
    public init(startHandler: ((Operation) -> Void)? = nil,
                cancelHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)? = nil,
                finishHandler: ((Operation, [Error]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.cancelHandler = cancelHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }
    
    public func operationDidCancel(_ operation: Operation) {
        cancelHandler?(operation)
    }
    
    public func operation(_ operation: Operation, didProduce newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        finishHandler?(operation, errors)
    }
}
