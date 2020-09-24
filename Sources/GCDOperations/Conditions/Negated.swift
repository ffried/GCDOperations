import class GCDCoreOperations.Operation
import protocol GCDCoreOperations.OperationCondition

/**
 A simple condition that negates the evaluation of another condition.
 This is useful (for example) if you want to only execute an operation if the
 network is NOT reachable.
 */
public struct NegatedCondition<ConditionToNegate: OperationCondition>: OperationCondition {
    public struct Error: ConditionError {
        public typealias Condition = NegatedCondition<ConditionToNegate>

        public let negatedCondition: ConditionToNegate
    }

    public static var name: String { "Not<\(ConditionToNegate.name)>" }
    public static var isMutuallyExclusive: Bool { ConditionToNegate.isMutuallyExclusive }
    
    private let condition: ConditionToNegate
    
    public init(condition: ConditionToNegate) {
        self.condition = condition
    }
    
    public func dependency(for operation: GCDOperation) -> GCDOperation? {
        condition.dependency(for: operation)
    }
    
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
