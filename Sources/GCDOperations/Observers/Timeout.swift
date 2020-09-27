import Dispatch
import typealias Foundation.TimeInterval
import typealias GCDCoreOperations.GCDOperation
import protocol GCDCoreOperations.OperationObserver

/// `TimeoutObserver` is a way to make an `Operation` automatically time out and cancel after a specified time interval.
public struct TimeoutObserver: OperationObserver {
    private let timeout: TimeInterval

    /// Creates a new TimeoutObserver with the given timeout.
    /// - Parameter timeout: The timeout after which the operation should be cancelled.
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    /// inherited
    public func operationDidStart(_ operation: GCDOperation) {
        // When the operation starts, queue up a block to cause it to time out.
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [timeout] in
            // Cancel the operation if it hasn't finished and hasn't already been cancelled.
            if !operation.isFinished && !operation.isCancelled {
                operation.cancel(with: TimeoutError(timeout: timeout))
            }
        }
    }

    /// inherited
    public func operation(_ operation: GCDOperation, didProduce newOperation: GCDOperation) {}
    /// inherited
    public func operationDidFinish(_ operation: GCDOperation, wasCancelled cancelled: Bool, errors: [Error]) {}
}

extension TimeoutObserver {
    /// The error that a timed out operation is cancelled with.
    public struct TimeoutError: Error, Equatable {
        /// The timeout that occurred.
        public let timeout: TimeInterval
        
        fileprivate init(timeout: TimeInterval) {
            self.timeout = timeout
        }
    }
}
