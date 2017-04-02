//
//  Operation.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrfcih. All rights reserved.
//

import Dispatch

open class Operation {
    // MARK: - Stored Properties
    private final lazy var startItem: DispatchWorkItem! = DispatchWorkItem(block: self.run)
    private final lazy var finishItem: DispatchWorkItem = DispatchWorkItem(block: {})
    
    private final var _state = Atomic<State>(.created)
    private final var state: State {
        get { return _state.value }
        set {
            precondition(state <= newValue, "Invalid state transition!")
            _state.value = newValue
        }
    }
    
    public private(set) final var observers: [OperationObserver] = []
    public private(set) final var conditions: [OperationCondition] = []
    
    private final var _dependencies = Atomic<ContiguousArray<Operation>>([])
    public private(set) var dependencies: ContiguousArray<Operation> {
        get { return _dependencies.value }
        set { _dependencies.value = newValue }
    }
    
    public private(set) var errors: [Error] = []
    
    // MARK: - Convenience State Accessors
    public final var isCancelled: Bool { return state.isCancelled }
    public final var isFinished: Bool { return state.isFinished }
    
    // MARK: - Dependency Management
    public final func addDependency(_ dep: Operation) {
        precondition(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
        dependencies.append(dep)
    }
    
    public final func removeDependency(_ dep: Operation) {
        precondition(state < .waitingForDependencies, "Can't modify dependencies after execution has begun!")
        _dependencies.withValue { if let idx = $0.index(where: { $0 === dep }) { $0.remove(at: idx) } }
    }
    
    // MARK: - Conditions
    public final func addCondition<Condition: OperationCondition>(_ condition: Condition) {
        precondition(state < .evaluatingConditions, "Can't modify conditions after evaluation has begun!")
        conditions.append(condition)
    }
    
    // MARK: - Observers
    public final func addObserver<Observer>(_ observer: Observer) where Observer: OperationObserver {
        guard !state.isFinished else { return }
        observers.append(observer)
    }
    
    // MARK: - Errors
    public final func aggregate(error: Error) {
        errors.append(error)
    }
    
    // MARK: - Lifecycle
    internal final func enqueue(on queue: DispatchQueue) {
        precondition(state < .enqueued, "Operation is already enqueued!")
        state = .enqueued
        queue.async(execute: startItem)
    }
    
    private final func run() {
        precondition(state == .enqueued, "Operation.run() called without the Operation being enqueued!")
        state = .waitingForDependencies
        waitForDependencies()
        
        state = .evaluatingConditions
        evaluateConditions {
            // Run
            self.state = .running
            self.observers.operationDidStart(self)
            self.execute()
        }
    }
    
    private final func waitForDependencies() {
        precondition(state == .waitingForDependencies, "Incorrect state for waitForDependencies!")
        /*
         * TODO: Using signal might be better.
         * This would also allow for dependencies being added while waiting for other dependencies.
         */
        dependencies.forEach { $0.finishItem.wait() }
    }
    
    private final func evaluateConditions(completion: @escaping () -> ()) {
        precondition(state == .evaluatingConditions, "Incorrect state for evaluateConditions!")
        
        let conditionGroup = DispatchGroup()
        
        var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluateForOperation(self) { result in
                //guard results[index] == nil else { return }
                precondition(results[index] == nil, "Completion of condition evalution called twice!")
                results[index] = result
                conditionGroup.leave()
            }
        }
        
        conditionGroup.notify(queue: .global()) {
            if self.state.isCancelled && self.errors.isEmpty {
                self.aggregate(error: ConditionError(name: "AnyCondition"))
            }
            
            let failures = results.flatMap { $0?.error }
            if !failures.isEmpty {
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
    
    private final func finish(cancelled: Bool, errors errs: [Error]) {
        guard !state.isFinished else { return }
        errors.append(contentsOf: errs)
        
        if cancelled {
            startItem.cancel()
            finishItem.cancel()
        }
        
        state = .finished(cancelled: cancelled)
        observers.operationDidFinish(self, errors: errors)
        
        // TODO: This might be bad for cancelled Operations that do not regularly check `isCancelled`
        finishItem.perform()
        
        // Cleanup to prevent any retain cycles
        startItem = nil
        observers.removeAll()
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
    
    // MARK: - Produce Operation
    public final func produce(_ operation: Operation) {
        observers.operation(self, didProduce: operation)
    }
}

// MARK: - Nested Types
fileprivate extension Operation {
    enum State: Comparable {
        case created
        case enqueued
        case waitingForDependencies
        case evaluatingConditions
        case running
        case finished(cancelled: Bool)
        
        var isFinished: Bool {
            if case .finished(_) = self {
                return true
            }
            return false
        }
        
        var isCancelled: Bool {
            if case .finished(let cancelled) = self {
                return cancelled
            }
            return false
        }
        
        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.created, .created),
                 (.enqueued, .enqueued),
                 (.waitingForDependencies, .waitingForDependencies),
                 (.evaluatingConditions, .evaluatingConditions),
                 (.running, .running):
                return true
            case (.finished(let lhsCanclled), .finished(let rhsCancelled)):
                return lhsCanclled == rhsCancelled
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
                 (.created, .finished(_)),
                 
                 (.enqueued, .waitingForDependencies),
                 (.enqueued, .evaluatingConditions),
                 (.enqueued, .running),
                 (.enqueued, .finished(_)),
                 
                 (.waitingForDependencies, .evaluatingConditions),
                 (.waitingForDependencies, .running),
                 (.waitingForDependencies, .finished(_)),
                 
                 (.evaluatingConditions, .running),
                 (.evaluatingConditions, .finished(_)),
                 
                 (.running, .finished(_)):
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
