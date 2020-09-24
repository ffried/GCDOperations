import Dispatch

open class Operation {
    // MARK: - Stored Properties
    private final lazy var startItem: DispatchWorkItem! = DispatchWorkItem(block: self.run)
    private final let finishItem = DispatchWorkItem(block: {})

    @Synchronized
    internal final var state: State = .created

    internal private(set) final var queue: DispatchQueue?
    
    public private(set) final var observers: [OperationObserver] = []
    public private(set) final var conditions: [OperationCondition] = []
    
    @Synchronized
    private final var _dependencies: ContiguousArray<Operation> = []

    public final var dependencies: ContiguousArray<Operation> { _dependencies }
    
    public private(set) final var errors: [Error] = []
    
    // MARK: - Convenience State Accessors
    public final var isCancelled: Bool { state.isCancelled }
    public final var isFinished: Bool { state.isFinished }
    
    // MARK: - Init
    public init() {}
    
    // MARK: - Dependency Management
    public final func addDependency(_ dep: Operation) {
        __dependencies.coordinated(with: _state) { deps, state in
            assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
            deps.append(dep)
        }
    }
    
    public final func removeDependency(_ dep: Operation) {
        __dependencies.coordinated(with: _state) { deps, state in
            assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
            deps.removeAll { $0 === dep }
        }
    }
    
    // MARK: - Conditions
    public final func addCondition<Condition>(_ condition: Condition) where Condition: OperationCondition {
        _state.withValue { state in
            assert(state < .evaluatingConditions, "Can't modify conditions after evaluation has begun!")
            conditions.append(condition)
        }
    }
    
    // MARK: - Observers
    public final func addObserver<Observer>(_ observer: Observer) where Observer: OperationObserver {
        let runManually: Bool = _state.withValue {
            let isFinished = $0.isFinished
            if !isFinished {
                observers.append(observer)
            }
            return isFinished
        }
        if runManually {
            observer.operationDidFinish(self, wasCancelled: state.isCancelled, errors: errors)
        }
    }
    
    // MARK: - Errors
    public final func aggregate<Errors>(errors newErrors: Errors) where Errors: Collection, Errors.Element: Error {
        errors.append(contentsOf: newErrors.lazy.map { $0 })
    }

    @inlinable
    public final func aggregate(errors: Error...) {
        aggregate(errors: errors)
    }

    @inlinable
    public final func aggregate(error: Error) {
        aggregate(errors: error)
    }
    
    // MARK: - Produce Operation
    public final func produce(_ operation: Operation) {
        observers.operation(self, didProduce: operation)
    }
    
    // MARK: - Lifecycle
    internal func enqueue(on queue: DispatchQueue, in group: DispatchGroup? = nil) {
        guard !isCancelled else { return }
        _state.withValue { state in
            assert(state < .enqueued, "Operation is already enqueued!")
            state = .enqueued
            self.queue = queue
        }
        if let group = group {
            queue.async(group: group, execute: startItem)
        } else {
            queue.async(execute: startItem)
        }
    }
    
    private final func run() {
        guard !isCancelled else { return }
        _state.withValue { state in
            assert(state == .enqueued, "\(#function) called without the Operation being enqueued!")
            state = .waitingForDependencies
        }
        waitForDependencies()

        guard !isCancelled else { return }
        _state.withValue { $0 = .evaluatingConditions }
        evaluateConditions {
            guard !self.isCancelled else { return }
            // Run
            self._state.withValue { $0 = .running }
            self.observers.operationDidStart(self)
            self.execute()
        }
    }
    
    private final func waitForDependencies() {
        assert(state == .waitingForDependencies, "Incorrect state for \(#function)!")
        /*
         * TODO: Using notify might be better.
         * This would also allow for dependencies being added while waiting for other dependencies.
         */
        dependencies.forEach { $0.finishItem.wait() }
    }
    
    private final func evaluateConditions(completion: @escaping () -> ()) {
        assert(state == .evaluatingConditions, "Incorrect state for \(#function)!")

        guard !conditions.isEmpty else { return completion() }
        
        let conditionGroup = DispatchGroup()
        
        var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluate(for: self) { result in
                //guard results[index] == nil else { return }
                assert(results[index] == nil, "Completion of condition evalution called twice!")
                results[index] = result
                conditionGroup.leave()
            }
        }
        
        conditionGroup.notify(queue: queue ?? .global()) {
            if self.state.isCancelled && self.errors.isEmpty {
                // TODO: Do we really need this? We could just assume it was cancelled for good.
                self.aggregate(error: AnyConditionFailed())
            }
            
            let failures: [Error] = results.compactMap { $0?.error }
            if !failures.isEmpty {
                // TODO: If operation was cancelled by condition, this won't do anything!
                self.finish(with: failures)
            } else {
                completion()
            }
        }
    }
    
    open func execute() {
        assertionFailure("Operations should always do some kind of work!")
        finish()
    }

    internal func handleCancellation() {}
    internal func handleFinishing() {}

    internal func cleanup() {
        // Cleanup to prevent any retain cycles
        startItem = nil
        queue = nil
        observers.removeAll()
    }

    private final func finish<Errors>(cancelled: Bool, errors errs: Errors)
    where Errors: Collection, Errors.Element: Error
    {
        assert(cancelled || state > .enqueued, "Finishing Operation that was never enqueued!")
        guard !state.isFinished else { return }

        _state.withValue { $0 = .finishing(cancelled: cancelled) }

        if cancelled {
            handleCancellation()
        } else {
            handleFinishing()
        }

        guard !state.isFinished else { return }

        aggregate(errors: errs)
        _state.withValue { $0 = .finished(cancelled: cancelled) }

        didFinish(wasCancelled: cancelled, errors: errors)
        observers.operationDidFinish(self, wasCancelled: cancelled, errors: errors)

        if cancelled {
            startItem.cancel()
            finishItem.cancel()
        } else {
            finishItem.perform()
        }
        
        cleanup()
    }
    
    public final func finish<Errors>(with errors: Errors) where Errors: Collection, Errors.Element: Error {
        finish(cancelled: false, errors: errors)
    }

    @inlinable
    public final func finish(with errors: Error...) {
        finish(with: errors)
    }

    public final func cancel<Errors>(with errors: Errors) where Errors: Collection, Errors.Element: Error {
        finish(cancelled: true, errors: errors)
    }

    @inlinable
    public final func cancel(with errors: Error...) {
        cancel(with: errors)
    }

    open func didFinish(wasCancelled: Bool, errors: [Error]) {}
}

// MARK: - Nested Types
extension Operation {
    enum State: Comparable, CustomStringConvertible {
        case created
        case enqueued
        case waitingForDependencies
        case evaluatingConditions
        case running
        case finishing(cancelled: Bool)
        case finished(cancelled: Bool)

        fileprivate var isFinishing: Bool {
            if case .finishing(_) = self {
                return true
            }
            return false
        }

        var isFinished: Bool {
            if case .finished(_) = self {
                return true
            }
            return false
        }
        
        var isCancelled: Bool {
            if case .finishing(let cancelled) = self {
                return cancelled
            }
            if case .finished(let cancelled) = self {
                return cancelled
            }
            return false
        }

        public var description: String {
            switch self {
            case .created: return "Created"
            case .enqueued: return "Enqueued"
            case .waitingForDependencies: return "Waiting for Dependencies"
            case .evaluatingConditions: return "Evaluating Conditions"
            case .running: return "Running"
            case .finishing(let cancelled): return cancelled ? "Cancelling" : "Finishing"
            case .finished(let cancelled): return cancelled ? "Cancelled" : "Finished"
            }
        }

        private var numericValue: Int {
            switch self {
            case .created: return 1
            case .enqueued: return 2
            case .waitingForDependencies: return 3
            case .evaluatingConditions: return 4
            case .running: return 5
            case .finishing(_): return 6
            case .finished(_): return 7
            }
        }
        
        static func <(lhs: State, rhs: State) -> Bool {
            lhs.numericValue < rhs.numericValue
        }
    }
}

fileprivate struct AnyConditionFailed: AnyConditionError {
    var conditionName: String { "AnyCondition" }
}
