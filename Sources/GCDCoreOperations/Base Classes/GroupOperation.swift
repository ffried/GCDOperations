import Dispatch

public final class GroupOperation: Operation {
    private let group = DispatchGroup()

    public private(set) var operations: ContiguousArray<Operation>

    public init(operations: ContiguousArray<Operation>) {
        self.operations = operations
    }
    
    public convenience init(operations: Operation...) {
        self.init(operations: ContiguousArray(operations))
    }

    public func addOperation(_ op: Operation) {
        assert(!isFinished, "Cannot add operations after GroupOperation has finished!")
        operations.append(op)
        if case .running = state, let queue = queue {
            includeOperation(op, on: queue)
        }
    }

    private final func includeOperation(_ op: Operation, on queue: DispatchQueue) {
        op.addObserver(BlockObserver(produceHandler: { [weak self] _, producedOp in self?.addOperation(producedOp) }))
        op.enqueue(on: queue, in: group)
    }

    public override func execute() {
        guard let queue = queue else { return finish() }
        operations.forEach { includeOperation($0, on: queue) }
        group.notify(queue: queue) { [unowned self] in
            guard !self.isCancelled else { return }
            self.finish()
        }
    }

    override func handleCancellation() {
        // Cancel all operations that reside within us
        operations.forEach { $0.cancel() }
        super.handleCancellation()
    }
}
