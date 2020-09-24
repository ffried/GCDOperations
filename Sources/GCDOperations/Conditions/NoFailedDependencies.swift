import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationCondition

/**
 A condition that specifies that every dependency must have succeeded.
 If any dependency has errors, the target operation will fail as well.
 */
public struct NoFailedDependencies: OperationCondition {
    public struct Error: ConditionError {
        public typealias Condition = NoFailedDependencies

        public let failedDependencies: ContiguousArray<GCDOperation>
    }

    public static let name = "NoFailedDependencies"
    public static let isMutuallyExclusive = false
    
    public init() {}
    
    public func dependency(for operation: GCDOperation) -> GCDOperation? { nil }
    
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
