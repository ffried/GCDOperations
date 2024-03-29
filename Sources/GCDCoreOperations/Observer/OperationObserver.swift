/// Describes a type that observers operations.
@preconcurrency
public protocol OperationObserver: Sendable {
    /// Invoked immediately prior to the ``Operation/execute()`` method.
    func operationDidStart(_ operation: Operation)
    
    /// Invoked when ``Operation/produce(_:)`` is executed.
    func operation(_ operation: Operation, didProduce newOperation: Operation)
    
    /// Invoked when an ``Operation`` finishes, along with whether it was cancelled and any errors produced during execution.
    func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: Array<some Error>)
}

// MARK: - Helper Extension
extension Sequence where Iterator.Element == any OperationObserver {
    @inlinable
    func operationDidStart(_ operation: Operation) {
        forEach { $0.operationDidStart(operation) }
    }

    @inlinable
    func operation(_ operation: Operation, didProduce newOperation: Operation) {
        forEach { $0.operation(operation, didProduce: newOperation) }
    }

    @inlinable
    func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: Array<some Error>) {
        forEach { $0.operationDidFinish(operation, wasCancelled: cancelled, errors: errors) }
    }
}
