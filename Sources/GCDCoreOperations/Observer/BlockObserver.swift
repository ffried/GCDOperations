public struct BlockObserver: OperationObserver {
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, Bool, [Error]) -> Void)?

    @usableFromInline
    init(_startHandler: ((Operation) -> Void)?,
         _produceHandler: ((Operation, Operation) -> Void)?,
         _finishHandler: ((Operation, Bool, [Error]) -> Void)?) {
        startHandler = _startHandler
        produceHandler = _produceHandler
        finishHandler = _finishHandler
    }

    @inlinable
    public init(startHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)? = nil,
                finishHandler: ((Operation, Bool, [Error]) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: produceHandler,
                  _finishHandler: finishHandler)
    }

    @inlinable
    public init(startHandler: ((Operation) -> Void)? = nil,
                produceHandler: ((Operation, Operation) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: produceHandler,
                  _finishHandler: nil)
    }

    @inlinable
    public init(startHandler: ((Operation) -> Void)?) {
        self.init(_startHandler: startHandler,
                  _produceHandler: nil,
                  _finishHandler: nil)
    }
    
    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }
    
    public func operation(_ operation: Operation, didProduce newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(_ operation: Operation, wasCancelled cancelled: Bool, errors: [Error]) {
        finishHandler?(operation, cancelled, errors)
    }
}
