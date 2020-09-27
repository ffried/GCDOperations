import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationCondition

/**
 A condition that specifies that every dependency must have succeeded.
 If any dependency has errors, the target operation will fail as well.
 */
public struct NoFailedDependencies: OperationCondition {
    /// The error produced when any of the operation's dependencies have failed.
    public struct Error: ConditionError {
        /// inherited
        public typealias Condition = NoFailedDependencies

        /// The dependencies that have failed.
        public let failedDependencies: ContiguousArray<GCDOperation>
    }

    /// inherited
    public static let name = "NoFailedDependencies"
    /// inhertied
    public static let isMutuallyExclusive = false

    /// Creates a new NoFailedDependencies condition.
    public init() {}

    /// inherited
    public func dependency(for operation: GCDOperation) -> GCDOperation? { nil }

    /// inherited
    public func evaluate(for operation: GCDOperation, completion: @escaping (OperationConditionResult) -> ()) {
        // Verify that all of the dependencies executed without errors.
        let failed = ContiguousArray(operation.dependencies.filter { !$0.errors.isEmpty })
        
        if !failed.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            completion(.failed(Error(failedDependencies: failed)))
        } else {
            completion(.satisfied)
        }
    }
}
