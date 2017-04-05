//
//  BlockObserver.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

public struct BlockObserver: OperationObserver {
    // MARK: Properties
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, Bool, [Error]) -> Void)?
    
    // MARK: Init
    public init(startHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)? = nil,
                finishHandler: ((Operation, Bool, [Error]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }
    
    public func operation(_ operation: Operation, didProduce newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: [Error]) {
        finishHandler?(operation, cancelled, errors)
    }
}
