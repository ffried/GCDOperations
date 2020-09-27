import Dispatch

/// The (abstract) base class for an operation.
/// An operation is an "isolated" piece of work, that will be enqueued and executed on an `OperationQueue`.
/// `Operation` is considered an abstract class and cannot be used directly. Create a subclass and override `execute` instead.
///
/// Each operation is in one of the following states:
/// - created -> The operation has been created but not yet added to an `OperationQueue`.
/// - waiting for dependencies -> The operation has been enqueued, but there are dependencies that are still executing.
/// - evaluating conditions -> All the operation's dependencies have finished and the operation is now evaluating its conditions.
/// - running -> The operation is performing its main task.
/// - finished -> The operation has finished its main taks, or was cancelled.
///
/// Note that an operation can be cancelled in any state, but its up to the subclass to periodically check on `isCancelled`.
///
/// An operation can have dependencies, which will have to finish before the operation starts its work.
/// Also, an operation can have conditions (see `OperationCondition`), which can be used to evaluate whether the operation should run or not.
/// Finally, an operation can be observed using `OperationObserver`.
///
/// Be aware, that once an operation has been enqueued, it should not be modified directly in terms of adding dependencies, conditions or observers.
open class Operation {
    private final lazy var startItem: DispatchWorkItem! = DispatchWorkItem(block: self.run)
    private final let finishItem = DispatchWorkItem(block: {})

    @Synchronized
    internal final var state: State = .created

    internal private(set) final var queue: DispatchQueue?

    /// The list of observers of this operation.
    public private(set) final var observers: [OperationObserver] = []
    /// The list of conditions of this operation.
    public private(set) final var conditions: [OperationCondition] = []
    
    @Synchronized
    private final var _dependencies: ContiguousArray<Operation> = []
    /// The list of dependencies of this operation.
    public final var dependencies: ContiguousArray<Operation> { _dependencies }

    /// The list of errors this operation encountered.
    public private(set) final var errors: [Error] = []
    
    // MARK: - State Accessors
    /// Whether or not this operation was cancelled.
    public final var isCancelled: Bool { state.isCancelled }
    /// Whether or not this operation has finished. This will also return `true` if the operation has been cancelled.
    public final var isFinished: Bool { state.isFinished }
    
    // MARK: - Init
    /// Creates a new operation.
    public init() {}
    
    // MARK: - Dependency Management
    /// Adds a dependency to this operation.
    /// - Parameter dep: The dependency to add.
    /// - Precondition: This must not be called after the operation has been enqueued.
    public final func addDependency(_ dep: Operation) {
        __dependencies.coordinated(with: _state) { deps, state in
            assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
            deps.append(dep)
        }
    }

    /// Removes a dependency from this operation.
    /// - Parameter dep: The dependency to remove.
    /// - Precondition: This must not be called after the operation has been enqueued.
    public final func removeDependency(_ dep: Operation) {
        __dependencies.coordinated(with: _state) { deps, state in
            assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
            deps.removeAll { $0 === dep }
        }
    }
    
    // MARK: - Conditions
    /// Adds a condition to this operation.
    /// - Parameter condition: The condition to add to this operation.
    /// - Precondition: This must not be called after the operation has been enqueued.
    public final func addCondition<Condition>(_ condition: Condition) where Condition: OperationCondition {
        _state.withValue { state in
            assert(state < .evaluatingConditions, "Can't modify conditions after evaluation has begun!")
            conditions.append(condition)
        }
    }
    
    // MARK: - Observers
    /// Adds an observer to this operation. The observer will get all calls that remain for this operation.
    /// If added to a running operation, the observer will only be notified of produced operations and finishing of this operation.
    /// If "added" to a finished operation, the observer will not be added to the list of observers
    /// and the `operationDidFinish(_:wasCancelled:errors:)` method will be called instantly on the observer.
    /// - Parameter observer: The observer to add to this operation.
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
    /// Aggregates a collection of errors into the list of errors of this operation.
    /// - Parameter newErrors: The collections of errors to aggregate.
    public final func aggregate<Errors>(errors newErrors: Errors) where Errors: Collection, Errors.Element: Error {
        errors.append(contentsOf: newErrors.lazy.map { $0 })
    }

    /// Aggregates a variadic list of errors into the list of errors of this operation.
    /// - Parameter newErrors: The variadic list of errors to aggregate.
    /// - SeeAlso: `aggregate(errors:)`
    @inlinable
    public final func aggregate(errors: Error...) {
        aggregate(errors: errors)
    }

    /// Aggregates an error into the list of errors of this operation.
    /// - Parameter error: The error to aggregate.
    /// - SeeAlso: `aggregate(errors:)`
    @inlinable
    public final func aggregate(error: Error) {
        aggregate(errors: error)
    }
    
    // MARK: - Produce Operation
    /// Produces a new operation. This notified all registered observers using the `operation(_:didProduce:)` method.
    /// - Parameter operation: The operation to produce.
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

    /// The main method of the operation. Subclasses should override this and perform their work.
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

    /// Finishes the operation with a list of errors (can be empty).
    /// - Parameter errors: The errors to finish with. Can be an empty collection.
    public final func finish<Errors>(with errors: Errors) where Errors: Collection, Errors.Element: Error {
        finish(cancelled: false, errors: errors)
    }

    /// Finishes the operation with a variadic list of errors (can be empty).
    /// - Parameter errors: The variadic list of errors to finish with.
    /// - SeeAlso: `finish(with:)`
    @inlinable
    public final func finish(with errors: Error...) {
        finish(with: errors)
    }

    /// Cancels the operation with a list of errors (can be empty).
    /// - Parameter errors: The errors to cancel with. Can be an empty collection.
    public final func cancel<Errors>(with errors: Errors) where Errors: Collection, Errors.Element: Error {
        finish(cancelled: true, errors: errors)
    }

    /// Cancels the operation with a variadic list of errors (can be empty).
    /// - Parameter errors: The variadic list of errors to cancel with.
    @inlinable
    public final func cancel(with errors: Error...) {
        cancel(with: errors)
    }

    /// Method for subclasses to override to be informed when the operation finishes. This can be used to e.g. clean up some internals.
    /// - Parameters:
    ///   - wasCancelled: Whether or not the operation was cancelled. The value is the same as `isCancelled`. It's passed to this method to prevent the locks that need to be taken for `isCancelled` to be retrieved.
    ///   - errors: The list of errors that the operation has aggregated. The value is the same as the `errors` property. It is passed to this method to prevent the locks that need to be taken for `errors` to be retrieved.
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

        var description: String {
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
