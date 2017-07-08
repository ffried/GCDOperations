//
//  Timeout.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 08.07.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationObserver
import typealias Foundation.TimeInterval

/**
    `TimeoutObserver` is a way to make an `Operation` automatically time out and
cancel after a specified time interval.
*/
public struct TimeoutObserver: OperationObserver {
    // MARK: Properties
    
    fileprivate let timeout: TimeInterval
    
    // MARK: Initialization
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    public func operationDidStart(_ operation: GCDCoreOperations.Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            /*
             Cancel the operation if it hasn't finished and hasn't already
             been cancelled.
             */
            if !operation.isFinished && !operation.isCancelled {
                operation.cancelWithError(TimeoutError(timeout: self.timeout))
            }
        }
    }
    
    public func operation(_ operation: GCDCoreOperations.Operation, didProduce newOperation: GCDCoreOperations.Operation) {}
    public func operationDidFinish(_ operation: GCDCoreOperations.Operation, wasCancelled cancelled: Bool, errors: [Error]) {}
}

public extension TimeoutObserver {
    public struct TimeoutError: Error, Equatable {
        public let timeout: TimeInterval
        
        fileprivate init(timeout: TimeInterval) {
            self.timeout = timeout
        }
        
        public static func ==(lhs: TimeoutError, rhs: TimeoutError) -> Bool {
            return lhs.timeout == rhs.timeout
        }
    }
}
