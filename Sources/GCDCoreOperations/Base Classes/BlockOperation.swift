/// A simple operation that runs a given block.
/// This operation can either execute a synchronous block and finish immediately afterwards,
/// or run an an asynchrounous block that is passed a reference to the `Operation.finish(with:)` method.
public final class BlockOperation: Operation {
    /// A block that runs synchronously.
    public typealias SyncBlock = () throws -> ()
    /// A block that runs asynchronously. `finish` is the reference to the `Operation.finish(with:)` method of the operation.
    public typealias AsyncBlock = (_ finish: @escaping @Sendable (Array<Error>) -> ()) -> ()

    private enum ExecutionMode {
        case sync(SyncBlock)
        case async(AsyncBlock)
    }

    private let executionMode: ExecutionMode

    /// Create a block operation, that runs a synchrounous block.
    /// - Parameter syncBlock: The block to execute.
    public init(syncBlock: @escaping SyncBlock) {
        executionMode = .sync(syncBlock)
    }

    /// Create a block operation that runs a asynchronous block.
    /// - Parameter asyncBlock: The block to execute.
    public init(asyncBlock: @escaping AsyncBlock) {
        executionMode = .async(asyncBlock)
    }

    /// inherited
    public override func execute() {
        switch executionMode {
        case .sync(let block):
            do {
                try block()
                finish()
            } catch {
                finish(with: error)
            }
        case .async(let block):
            block { self.finish(with: $0) }
        }
    }
}
