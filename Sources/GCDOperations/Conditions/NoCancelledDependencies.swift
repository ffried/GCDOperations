import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationCondition

/**
 A condition that specifies that every dependency must have run.
 If any dependency was cancelled, the target operation will fail.
 */
public struct NoCancelledDependencies: OperationCondition {
    public struct Error: ConditionError {
        public typealias Condition = NoCancelledDependencies

        public let cancelledDependencies: ContiguousArray<GCDOperation>
    }

    public static let name = "NoCancelledDependencies"
    public static let isMutuallyExclusive = false
    
    public init() {}
    
    public func dependency(for operation: GCDOperation) -> GCDOperation? { nil }
    
    public func evaluate(for operation: GCDOperation, completion: @escaping (OperationConditionResult) -> ()) {
        // Verify that all of the dependencies executed.
        let cancelled = ContiguousArray(operation.dependencies.lazy.filter(\.isCancelled))
        
        if !cancelled.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            completion(.failed(Error(cancelledDependencies: cancelled)))
        } else {
            completion(.satisfied)
        }
    }
}
