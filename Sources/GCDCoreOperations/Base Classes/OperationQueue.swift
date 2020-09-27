import Dispatch
#if os(Linux)
    import func CoreFoundation._CFIsMainThread
#endif

private func isMainThread() -> Bool {
    #if os(Linux)
        return _CFIsMainThread()
    #else
        return pthread_main_np() != 0
    #endif
}

private let _operationQueueKey = DispatchSpecificKey<Unmanaged<OperationQueue>>()
fileprivate extension DispatchSpecificKey {
    static var operationQueue: DispatchSpecificKey<Unmanaged<OperationQueue>> { _operationQueueKey }
}

fileprivate extension Operation {
    var _queueID: Int { unsafeBitCast(self, to: Int.self) } // pointer ought to be unique
}

/// An operation queue is used to execute `Operation`s. It is backed by a concurrent `DispatchQueue`.
/// It takes care of enqueuing operations and also enqueues any produced operations.
public final class OperationQueue {
    private final class QueueObserver: OperationObserver {
        private(set) var queue: OperationQueue!

        init(queue: OperationQueue) {
            self.queue = queue
        }

        func operationDidStart(_ operation: Operation) {}

        func operation(_ operation: Operation, didProduce newOperation: Operation) {
            queue.addOperation(newOperation)
        }

        func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: [Error]) {
            queue.operationFinished(operation)
            queue = nil // Op has finished. Release the queue.
        }
    }

    private let lockQueue = DispatchQueue(label: "net.ffried.GCDOperations.OperationQueue.Lock")

    private let queue: DispatchQueue
    private let operationsGroup = DispatchGroup()
    private var operations: Dictionary<Int, Operation> = [:]

    /// Whether or not the queue is currently suspended.
    public private(set) var isSuspended: Bool

    fileprivate init(queue: DispatchQueue, isSuspended: Bool) {
        self.queue = queue
        self.isSuspended = isSuspended

        queue.setSpecific(key: .operationQueue, value: .passUnretained(self))
    }

    /// Creates a new operation queue, optionally suspending it initially.
    /// - Parameter initiallySuspended: Whether the new OperationQueue should be suspended. Defaults to `false`.
    public convenience init(initiallySuspended: Bool = false) {
        let queue = DispatchQueue(label: "net.ffried.GCDOperations.OperationQueue.Queue",
                                  attributes: [.initiallyInactive, .concurrent])
        if initiallySuspended {
            queue.suspend()
        } else {
            queue.activate()
        }
        self.init(queue: queue, isSuspended: initiallySuspended)
    }

    deinit {
        queue.setSpecific(key: .operationQueue, value: nil)
    }

    /// Suspnds the operation queue.
    public func suspend() {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            queue.suspend()
            isSuspended = true
        }
    }

    /// Resumes the operation queue.
    public func resume() {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            isSuspended = false
            queue.activate()
            queue.resume()
        }
    }

    private func _unsafeAddOperation(_ op: Operation) {
        dispatchPrecondition(condition: .onQueue(lockQueue))
        operationsGroup.enter()
        op.addObserver(QueueObserver(queue: self))
        let operationIdentifier = op._queueID
        assert(operations[operationIdentifier] == nil, "Operation \(op) has already been added to this queue!")
        operations[operationIdentifier] = op

        op.conditions.lazy
            .compactMap { $0.dependency(for: op) }
            .forEach {
                op.addDependency($0)
                _unsafeAddOperation($0)
        }

        let concurrencyCategories = op.conditions
            .lazy
            .map { type(of: $0) }
            .filter { $0.isMutuallyExclusive }
            .map { String(describing: $0) }
        if !concurrencyCategories.isEmpty {
            ExclusivityController.addOperation(op, categories: concurrencyCategories)
            op.addObserver(BlockObserver(finishHandler: { op, _, _ in
                ExclusivityController.removeOperation(op, categories: concurrencyCategories)
            }))
        }

        op.enqueue(on: queue)
    }

    private func operationFinished(_ op: Operation) {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            let opID = op._queueID
            assert(operations[opID] != nil, "Operation \(op) is not enqueued in this queue!")
            operations.removeValue(forKey: opID)
            operationsGroup.leave()
        }
    }

    /// Adds a new operation to this queue.
    /// - Parameter op: The operation to add.
    public func addOperation(_ op: Operation) {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync { _unsafeAddOperation(op) }
    }

    /// Adds a collection of operations to this queue.
    /// - Parameter ops: The operations to add.
    public func addOperations<Operations>(_ ops: Operations)
    where Operations: Collection, Operations.Element == Operation
    {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync { ops.forEach(_unsafeAddOperation) }
    }

    /// Adds a variadic list of operations to this queue.
    /// - Parameter ops: The variadic list of operations to add.
    /// - SeeAlso: `OperationQueue.addOperations(_:)`
    @inlinable
    public func addOperations(_ ops: Operation...) {
        addOperations(ops)
    }

    /// Adds a `BlockOperation` with a given synchronous block.
    /// - Parameter block: The block to execute.
    /// - Returns: The created block operation.
    /// - SeeAlso: `BlockOperation.init(syncBlock:)`
    @inlinable
    @discardableResult
    public func addOperation(executingSync block: @escaping BlockOperation.SyncBlock) -> BlockOperation {
        let operation = BlockOperation(syncBlock: block)
        addOperation(operation)
        return operation
    }

    /// Adds a `BlockOperation` with a given asynchronous block.
    /// - Parameter block: The block to execute.
    /// - Returns: The created block operation.
    /// - SeeAlso: `BlockOperation.init(asyncBlock:)`
    @inlinable
    @discardableResult
    public func addOperation(executingAsync block: @escaping BlockOperation.AsyncBlock) -> BlockOperation {
        let operation = BlockOperation(asyncBlock: block)
        addOperation(operation)
        return operation
    }

    /// Cancels all operation that are currently in the queue.
    public func cancelAllOperations() {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync { operations.values }.forEach { $0.cancel() }
    }
}

extension OperationQueue {
    /// The `OperationQueue` associated to the main queue.
    public static var main: OperationQueue {
        DispatchQueue.main.getSpecific(key: .operationQueue)?.takeUnretainedValue() ?? .init(queue: .main, isSuspended: false)
    }

    /// If the current queue belongs to an `OperationQueue` it will be returned here. `nil` otherwise.
    public static var current: OperationQueue? {
        DispatchQueue.getSpecific(key: .operationQueue)?.takeUnretainedValue() ?? (isMainThread() ? .main : nil)
    }
}
