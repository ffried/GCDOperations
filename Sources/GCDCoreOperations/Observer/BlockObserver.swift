/// A simple `OperationObserver` implementation that executes blocks for each of the methods.
public struct BlockObserver: OperationObserver {
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, Bool, Array<Error>) -> Void)?

    @usableFromInline
    init(_startHandler: ((Operation) -> Void)?,
         _produceHandler: ((Operation, Operation) -> Void)?,
         _finishHandler: ((Operation, Bool, Array<Error>) -> Void)?) {
        startHandler = _startHandler
        produceHandler = _produceHandler
        finishHandler = _finishHandler
    }

    /// Creates a new block observer with the given start, produce and finish handlers.
    /// - Parameters:
    ///   - startHandler: The block to execute when an operation starts.
    ///   - produceHandler: The block to execute when an operation produces another operation.
    ///   - finishHandler: The block to execute when an operation finishes.
    @inlinable
    public init(startHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)? = nil,
                finishHandler: ((Operation, Bool, Array<Error>) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: produceHandler,
                  _finishHandler: finishHandler)
    }

    /// Creates a new block observer with the given start and produce handlers.
    /// - Parameters:
    ///   - startHandler: The block to execute when an operation starts.
    ///   - produceHandler: The block to execute when an operation produces another operation.
    @inlinable
    public init(startHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: produceHandler,
                  _finishHandler: nil)
    }

    /// Creates a new block observer with the given start handler.
    /// - Parameter startHandler: The block to execute when an operation starts.
    @inlinable
    public init(startHandler: ((Operation) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: nil,
                  _finishHandler: nil)
    }

    /// inherited
    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }

    /// inherited
    public func operation(_ operation: Operation, didProduce newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }

    /// inherited
    public func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: Array<Error>) {
        finishHandler?(operation, cancelled, errors)
    }
}
