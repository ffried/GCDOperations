import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusive<T>: OperationCondition {
    /// inherited
    public static var name: String { "MutuallyExclusive<\(T.self)>" }
    /// inherited
    public static var isMutuallyExclusive: Bool { true }

    /// Creates a new MutuallyExclusive condition.
    public init() {}

    /// inherited
    public func dependency(for operation: GCDCoreOperations.Operation) -> GCDCoreOperations.Operation? { nil }

    /// inherited
    public func evaluate(for operation: GCDCoreOperations.Operation, completion: @escaping (OperationConditionResult) -> ()) {
        completion(.satisfied)
    }
}
