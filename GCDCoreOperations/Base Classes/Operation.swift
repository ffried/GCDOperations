//
//  Operation.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import Dispatch

open class Operation {
    // MARK: - Stored Properties
    private final lazy var startItem: DispatchWorkItem! = DispatchWorkItem(block: self.run)
    private final let finishItem = DispatchWorkItem(block: {})

    private final var _state = Atomic<State>(.created)
    internal final var state: State {
        get { return _state.value }
        set {
            _state.withValue {
                assert($0 <= newValue, "Invalid state transition!")
                $0 = newValue
            }
        }
    }
    
    public private(set) final var observers: [OperationObserver] = []
    public private(set) final var conditions: [OperationCondition] = []
    
    private final var _dependencies = Atomic<ContiguousArray<Operation>>([])
    public final var dependencies: ContiguousArray<Operation> { return _dependencies.value }
    
    public private(set) final var errors: [Error] = []
    
    // MARK: - Convenience State Accessors
    public final var isCancelled: Bool { return state.isCancelled }
    public final var isFinished: Bool { return state.isFinished }
    
    // MARK: - Init
    public init() {}
    
    // MARK: - Dependency Management
    public final func addDependency(_ dep: Operation) {
        assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
        _dependencies.withValue { $0.append(dep) }
    }
    
    public final func removeDependency(_ dep: Operation) {
        assert(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
        _dependencies.withValue { if let idx = $0.index(where: { $0 === dep }) { $0.remove(at: idx) } }
    }
    
    // MARK: - Conditions
    public final func addCondition<Condition>(_ condition: Condition) where Condition: OperationCondition {
        assert(state < .evaluatingConditions, "Can't modify conditions after evaluation has begun!")
        conditions.append(condition)
    }
    
    // MARK: - Observers
    public final func addObserver<Observer>(_ observer: Observer) where Observer: OperationObserver {
        guard !state.isFinished else {
            observer.operationDidFinish(self, wasCancelled: state.isCancelled, errors: errors)
            return
        }
        observers.append(observer)
    }
    
    // MARK: - Errors
    public final func aggregate(error: Error) {
        errors.append(error)
    }
    
    // MARK: - Produce Operation
    public final func produce(_ operation: Operation) {
        observers.operation(self, didProduce: operation)
    }
    
    // MARK: - Lifecycle
    internal func enqueue(on queue: DispatchQueue, in group: DispatchGroup? = nil) {
        guard !isCancelled else { return }
        assert(state < .enqueued, "Operation is already enqueued!")
        state = .enqueued
        if let group = group {
            queue.async(group: group, execute: startItem)
        } else {
            queue.async(execute: startItem)
        }
    }
    
    private final func run() {
        guard !isCancelled else { return }
        assert(state == .enqueued, "Operation.run() called without the Operation being enqueued!")
        state = .waitingForDependencies
        waitForDependencies()

        guard !isCancelled else { return }
        state = .evaluatingConditions
        evaluateConditions {
            guard !self.isCancelled else { return }
            // Run
            self.state = .running
            self.observers.operationDidStart(self)
            self.execute()
        }
    }
    
    private final func waitForDependencies() {
        assert(state == .waitingForDependencies, "Incorrect state for waitForDependencies!")
        /*
         * TODO: Using notify might be better.
         * This would also allow for dependencies being added while waiting for other dependencies.
         */
        dependencies.forEach { $0.finishItem.wait() }
    }
    
    private final func evaluateConditions(completion: @escaping () -> ()) {
        assert(state == .evaluatingConditions, "Incorrect state for evaluateConditions!")

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
        
        conditionGroup.notify(queue: .global()) {
            if self.state.isCancelled && self.errors.isEmpty {
                // TODO: Do we really need this? We could just assume it was cancelled for good.
                self.aggregate(error: ConditionError(name: "AnyCondition"))
            }
            
            let failures = results.flatMap { $0?.error }
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
        observers.removeAll()
    }

    private final func finish(cancelled: Bool, errors errs: [Error]) {
        assert(cancelled || state > .enqueued, "Finishing Operation that was never enqueued!")
        guard !state.isFinished else { return }

        state = .finishing(cancelled: cancelled)

        if cancelled {
            handleCancellation()
        } else {
            handleFinishing()
        }

        guard !state.isFinished else { return }

        errors.append(contentsOf: errs)
        state = .finished(cancelled: cancelled)

        didFinish()
        observers.operationDidFinish(self, wasCancelled: cancelled, errors: errors)

        if cancelled {
            startItem.cancel()
            finishItem.cancel()
        } else {
            // TODO: This might be bad for cancelled Operations that do not regularly check `isCancelled`
            finishItem.perform()
        }
        
        cleanup()
    }
    
    public final func finish(with errors: [Error] = []) {
        finish(cancelled: false, errors: errors)
    }
    
    public final func finish(with errors: Error...) {
        finish(with: errors)
    }
    
    public final func cancel(with errors: [Error] = []) {
        finish(cancelled: true, errors: errors)
    }
    
    public final func cancel(with errors: Error...) {
        cancel(with: errors)
    }

    open func didFinish() {}
}

// MARK: - Nested Types
internal extension Operation {
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

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.created, .created),
                 (.enqueued, .enqueued),
                 (.waitingForDependencies, .waitingForDependencies),
                 (.evaluatingConditions, .evaluatingConditions),
                 (.running, .running):
                return true
            case (.finishing(let lhsCancelled), .finishing(let rhsCancelled)),
                 (.finished(let lhsCancelled), .finished(let rhsCancelled)):
                return lhsCancelled == rhsCancelled
            default:
                return false
            }
        }
        
        static func <(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.created, .enqueued),
                 (.created, .waitingForDependencies),
                 (.created, .evaluatingConditions),
                 (.created, .running),
                 (.created, .finishing(_)),
                 (.created, .finished(_)),
                 
                 (.enqueued, .waitingForDependencies),
                 (.enqueued, .evaluatingConditions),
                 (.enqueued, .running),
                 (.enqueued, .finishing(_)),
                 (.enqueued, .finished(_)),
                 
                 (.waitingForDependencies, .evaluatingConditions),
                 (.waitingForDependencies, .running),
                 (.waitingForDependencies, .finishing(_)),
                 (.waitingForDependencies, .finished(_)),
                 
                 (.evaluatingConditions, .running),
                 (.evaluatingConditions, .finishing(_)),
                 (.evaluatingConditions, .finished(_)),

                 (.running, .finishing(_)),
                 (.running, .finished(_)),

                 (.finishing(_), .finished(_)):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Extensions
fileprivate extension ConditionError {
    init(name: String, errorInformation: ErrorInformation? = nil) {
        self.conditionName = name
        self.information = errorInformation
    }
}
