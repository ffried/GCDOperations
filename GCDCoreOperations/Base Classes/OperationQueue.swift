//
//  OperationQueue.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

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
    static var operationQueue: DispatchSpecificKey<Unmanaged<OperationQueue>> { return _operationQueueKey }
}

public final class OperationQueue {
    private let lockQueue = DispatchQueue(label: "net.ffried.GCDOperations.OperationQueue.Lock")

    private let queue: DispatchQueue
    private var operations: ContiguousArray<Operation> = []

    public private(set) var isSuspended: Bool
    
    public convenience init(initiallySuspended: Bool = false) {
        let attributes: DispatchQueue.Attributes
        if #available(
            iOS 10.0, iOSApplicationExtension 10.0,
            macOS 10.12, macOSApplicationExtension 10.12,
            tvOS 10.0, tvOSApplicationExtension 10.0,
            watchOS 3.0, watchOSApplicationExtension 3.0, *) {
            attributes = [.initiallyInactive, .concurrent]
        } else {
            attributes = [.concurrent]
        }
        let queue = DispatchQueue(label: "net.ffried.GCDOperations.OperationQueue.Queue", attributes: attributes)
        if initiallySuspended {
            queue.suspend()
        } else if #available(
                  iOS 10.0, iOSApplicationExtension 10.0,
                  macOS 10.12, macOSApplicationExtension 10.12,
                  tvOS 10.0, tvOSApplicationExtension 10.0,
                  watchOS 3.0, watchOSApplicationExtension 3.0, *) {
            queue.activate()
        }
        self.init(queue: queue, isSuspended: initiallySuspended)
    }

    fileprivate init(queue: DispatchQueue, isSuspended: Bool) {
        self.queue = queue
        self.isSuspended = isSuspended

        queue.setSpecific(key: .operationQueue, value: .passUnretained(self))
    }
    
    public func suspend() {
        lockQueue.sync {
            queue.suspend()
            isSuspended = true
        }
    }
    
    public func resume() {
        lockQueue.sync {
            isSuspended = false
            if #available(
               iOS 10.0, iOSApplicationExtension 10.0,
               macOS 10.12, macOSApplicationExtension 10.12,
               tvOS 10.0, tvOSApplicationExtension 10.0,
               watchOS 3.0, watchOSApplicationExtension 3.0, *) {
                queue.activate()
            }
            queue.resume()
        }
    }

    private func _unsafeAddOperation(_ op: Operation) {
        op.addObserver(BlockObserver(produceHandler: { [weak self] in self?.addOperation($1) },
                                     finishHandler: { [weak self] in self?.operationFinished($0.0) }))
        operations.append(op)

        let dependencies = op.conditions.flatMap { $0.dependencyForOperation(op) }
        dependencies.forEach {
            op.addDependency($0)
            _unsafeAddOperation($0)
        }

        let concurrencyCategories = op.conditions
            .map { type(of: $0) }
            .filter { $0.isMutuallyExclusive }
            .map { String(describing: $0) }
        if !concurrencyCategories.isEmpty {
            ExclusivityController.addOperation(op, categories: concurrencyCategories)
            op.addObserver(BlockObserver(finishHandler: {
                ExclusivityController.removeOperation($0.0, categories: concurrencyCategories)
            }))
        }

        op.enqueue(on: queue)
    }

    public func addOperation(_ op: Operation) {
        lockQueue.sync { _unsafeAddOperation(op) }
    }
    
    private final func operationFinished(_ op: Operation) {
        lockQueue.sync {
            _ = operations.index(where: { $0 === op }).map { operations.remove(at: $0) }
        }
    }
    
    public func cancelAllOperations() {
        lockQueue.sync {
            operations.forEach { $0.cancel() }
        }
    }
}

public extension OperationQueue {
    public static var main: OperationQueue {
        return DispatchQueue.main.getSpecific(key: .operationQueue)?.takeUnretainedValue() ?? .init(queue: .main, isSuspended: false)
    }

    public static var current: OperationQueue? {
        return DispatchQueue.getSpecific(key: .operationQueue)?.takeUnretainedValue() ?? (isMainThread() ? .main : nil)
    }
}
