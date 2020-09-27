import Dispatch

/// An operation that groups several operations under it.
public final class GroupOperation: Operation {
    private let group = DispatchGroup()

    /// The operations grouped inside this operation.
    public private(set) var operations: ContiguousArray<Operation>

    /// Creates a new GroupOperation with the given list of operations.
    /// - Parameter operations: The operations to execute grouped in this operation.
    public init(operations: ContiguousArray<Operation>) {
        self.operations = operations
    }

    /// Creates a new GroupOperation with the given variadic list of operations.
    /// - Parameter operations: The variadic list of operations to execute grouped in this operation.
    public convenience init(operations: Operation...) {
        self.init(operations: ContiguousArray(operations))
    }

    /// Adds a new operation to this GroupOperation.
    /// - Parameter op: The operation to add.
    /// - Precondition: This GroupOperation must not have finished yet!
    public func addOperation(_ op: Operation) {
        assert(!isFinished, "Cannot add operations after GroupOperation has finished!")
        operations.append(op)
        if case .running = state, let queue = queue {
            includeOperation(op, on: queue)
        }
    }

    /// Adds a collection of operations to this GroupOperation.
    /// - Parameter ops: The operations to add.
    /// - Precondition: The GroupOperation must not have finished yet!
    public func addOperations<Operations>(_ ops: Operations)
    where Operations: Collection, Operations.Element == Operation
    {
        assert(!isFinished, "Cannot add operations after GroupOperation has finished!")
        operations.append(contentsOf: ops)
        if case .running = state, let queue = queue {
            ops.forEach { includeOperation($0, on: queue) }
        }
    }

    /// Adds a variadic list of operations to this GroupOperation.
    /// - Parameter ops: The variadic list of operations to add.
    /// - Precondition: The GroupOperation must not have finished yet!
    /// - SeeAlso: `GroupOperation.addOperations(_:)`
    @inlinable
    public func addOperations(_ ops: Operation...) {
        addOperations(ops)
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
