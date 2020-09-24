import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationCondition

/**
 A simple condition that causes another condition to not enqueue its dependency.
 This is useful (for example) when you want to verify that you have access to
 the user's location, but you do not want to prompt them for permission if you
 do not already have it.
 */
public struct SilentCondition<Condition: OperationCondition>: OperationCondition {
    public static var name: String { "Silent<\(Condition.name)>" }
    
    public static var isMutuallyExclusive: Bool { Condition.isMutuallyExclusive }
    
    private let condition: Condition
    
    public init(condition: Condition) {
        self.condition = condition
    }
    
    public func dependency(for operation: GCDOperation) -> GCDOperation? {
        // We never generate a dependency.
        nil
    }
    
    public func evaluate(for operation: GCDOperation, completion: @escaping (OperationConditionResult) -> ()) {
        condition.evaluate(for: operation, completion: completion)
    }
}
