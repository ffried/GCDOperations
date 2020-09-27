import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationCondition

/**
 A simple condition that causes another condition to not enqueue its dependency.
 This is useful (for example) when you want to verify that you have access to
 the user's location, but you do not want to prompt them for permission if you
 do not already have it.
 */
public struct SilentCondition<Condition: OperationCondition>: OperationCondition {
    /// inherited
    public static var name: String { "Silent<\(Condition.name)>" }

    /// inherited
    public static var isMutuallyExclusive: Bool { Condition.isMutuallyExclusive }
    
    private let condition: Condition

    /// Creates a new SilentCondition that silences the given condition.
    /// - Parameter condition: The condition to silence.
    public init(condition: Condition) {
        self.condition = condition
    }

    /// inherited
    public func dependency(for operation: GCDOperation) -> GCDOperation? {
        // We never generate a dependency.
        nil
    }

    /// inherited
    public func evaluate(for operation: GCDOperation, completion: @escaping (OperationConditionResult) -> ()) {
        condition.evaluate(for: operation, completion: completion)
    }
}
