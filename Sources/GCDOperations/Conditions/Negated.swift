import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/**
 A simple condition that negates the evaluation of another condition.
 This is useful (for example) if you want to only execute an operation if the
 network is NOT reachable.
 */
public struct NegatedCondition<ConditionToNegate: OperationCondition>: OperationCondition {
    /// The error produced, when the negated condition succeeded.
    public struct Error: ConditionError {
        public typealias Condition = NegatedCondition<ConditionToNegate>

        /// The condition that was negated but succeeded.
        public let negatedCondition: ConditionToNegate
    }

    /// inherited
    public static var name: String { "Not<\(ConditionToNegate.name)>" }
    /// inherited
    public static var isMutuallyExclusive: Bool { ConditionToNegate.isMutuallyExclusive }
    
    private let condition: ConditionToNegate

    /// Creates a new NegatedCondition, that negates the given conditio.
    /// - Parameter condition: The condition to negate.
    public init(condition: ConditionToNegate) {
        self.condition = condition
    }

    /// inherited
    public func dependency(for operation: GCDOperation) -> GCDOperation? {
        condition.dependency(for: operation)
    }

    /// inherited
    public func evaluate(for operation: GCDOperation, completion: @escaping (OperationConditionResult) -> ()) {
        condition.evaluate(for: operation) {
            switch $0 {
            case .failed(_):
                // If the composed condition failed, then this one succeeded.
                completion(.satisfied)
            case .satisfied:
                // If the composed condition succeeded, then this one failed.
                completion(.failed(Error(negatedCondition: condition)))
            }
        }
    }
}
