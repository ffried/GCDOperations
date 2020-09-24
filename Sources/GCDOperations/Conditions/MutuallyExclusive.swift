import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusive<T>: OperationCondition {
    public static var name: String { "MutuallyExclusive<\(T.self)>" }
    public static var isMutuallyExclusive: Bool { true }
    
    public init() {}
    
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? { nil }
    
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        completion(.satisfied)
    }
}
