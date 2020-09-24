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

public final class OperationQueue {
    private let lockQueue = DispatchQueue(label: "net.ffried.GCDOperations.OperationQueue.Lock")

    private let queue: DispatchQueue
    private let operationsGroup = DispatchGroup()
    private var operations: ContiguousArray<Operation> = []

    public private(set) var isSuspended: Bool

    fileprivate init(queue: DispatchQueue, isSuspended: Bool) {
        self.queue = queue
        self.isSuspended = isSuspended

        queue.setSpecific(key: .operationQueue, value: .passUnretained(self))
    }
    
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
    
    public func suspend() {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            queue.suspend()
            isSuspended = true
        }
    }
    
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
        op.addObserver(BlockObserver(produceHandler: { [weak self] in self?.addOperation($1) },
                                     finishHandler: { [weak self] op, _, _ in self?.operationFinished(op) }))
        operations.append(op)

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

    public func addOperation(_ op: Operation) {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync { _unsafeAddOperation(op) }
    }

    public func addOperations<Operations>(_ ops: Operations)
    where Operations: Collection, Operations.Element == Operation
    {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync { ops.forEach(_unsafeAddOperation) }
    }

    @inlinable
    public func addOperations(_ ops: Operation...) {
        addOperations(ops)
    }

    @inlinable
    @discardableResult
    public func addOperation(executing block: @escaping BlockOperation.Block) -> BlockOperation {
        let operation = BlockOperation(block: block)
        addOperation(operation)
        return operation
    }
    
    private func operationFinished(_ op: Operation) {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            _ = operations.firstIndex(where: { $0 === op }).map { operations.remove(at: $0) }
            operationsGroup.leave()
        }
    }
    
    public func cancelAllOperations() {
        dispatchPrecondition(condition: .notOnQueue(lockQueue))
        lockQueue.sync {
            operations.forEach { $0.cancel() }
        }
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
