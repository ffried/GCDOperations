//
//  OperationCondition.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

/**
    A protocol for defining conditions that must be satisfied in order for an
    operation to begin execution.
*/
public protocol OperationCondition {
    /** 
        The name of the condition. This is will be passed as `conditionName` in `ConditionError`s.
    */
    static var name: String { get }
    
    /**
        Specifies whether multiple instances of the conditionalized operation may
        be executing simultaneously.
    */
    static var isMutuallyExclusive: Bool { get }
    
    /**
        Some conditions may have the ability to satisfy the condition if another
        operation is executed first. Use this method to return an operation that
        (for example) asks for permission to perform the operation
        
        - parameter operation: The `Operation` to which the Condition has been added.
        - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
        - note: Only a single operation may be returned as a dependency. If you 
            find that you need to return multiple operations, then you should be
            expressing that as multiple conditions. Alternatively, you could return
            a single `GroupOperation` that executes multiple operations internally.
    */
    func dependencyForOperation(_ operation: Operation) -> Operation?
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void)
}

/**
    An enum to indicate whether an `OperationCondition` was satisfied, or if it 
    failed with an error.
*/
public enum OperationConditionResult {
    case satisfied
    case failed(ConditionError)
    
    var error: ConditionError? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
    
    public static func ==(lhs: OperationConditionResult, rhs: OperationConditionResult) -> Bool {
        switch (lhs, rhs) {
        case (.satisfied, .satisfied):
            return true
        case (.failed(let lError), .failed(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}
