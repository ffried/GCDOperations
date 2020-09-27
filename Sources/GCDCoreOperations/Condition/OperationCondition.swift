/// A protocol for defining conditions that must be satisfied in order for an operation to begin execution.
public protocol OperationCondition {
    /// The name of the condition. This is will be passed as `conditionName` in `ConditionError`s.
    static var name: String { get }

    /// Specifies whether multiple instances of the conditionalized operation may
    /// be executing simultaneously.
    static var isMutuallyExclusive: Bool { get }

    /**
        Some conditions may have the ability to satisfy the condition if another
        operation is executed first. Use this method to return an operation that
        (for example) asks for permission to perform the operation
        
        - parameter operation: The `Operation` to which the Condition has been added.
        - returns: An `Operation`, if a dependency should be automatically added. Otherwise, `nil`.
        - note: Only a single operation may be returned as a dependency. If you 
            find that you need to return multiple operations, then you should be
            expressing that as multiple conditions. Alternatively, you could return
            a single `GroupOperation` that executes multiple operations internally.
    */
    func dependency(for operation: Operation) -> Operation?

    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> ())
}

/// An error representing a failed condition. This protocol is an implementation detail and should not be used directly. Use `ConditionError` instead.
public protocol AnyConditionError: Error {
    /// The name of the condition that failed.
    var conditionName: String { get }
}

/// An error describing a failed condition.
public protocol ConditionError: AnyConditionError {
    /// The condition that has failed.
    associatedtype Condition: OperationCondition
}

extension ConditionError {
    @inlinable
    public var conditionName: String { Condition.name }
}


/// An enum to indicate whether an `OperationCondition` was satisfied, or if it
/// failed with an error.
///
/// - satisfied: The condition was satisified, continue execution.
/// - failed: The condition failed, abort execution.
///     The associated `ConditionError` describes what failure happened during evaluation.
public enum OperationConditionResult {
    case satisfied
    case failed(AnyConditionError)
    
    var error: AnyConditionError? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
}
