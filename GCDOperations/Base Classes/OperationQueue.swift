//
//  OperationQueue.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import Dispatch

public final class OperationQueue {
    private let queue: DispatchQueue
    
    private var operations = Atomic<ContiguousArray<Operation>>([])
    
    public private(set) var isSuspended: Bool
    
    public init(initiallySuspended: Bool = false) {
        isSuspended = initiallySuspended
        
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
        queue = .init(label: "net.ffried.GCDOperations.Queue", attributes: attributes)
        
        if isSuspended {
            queue.suspend()
        } else if #available(
            iOS 10.0, iOSApplicationExtension 10.0,
            macOS 10.12, macOSApplicationExtension 10.12,
            tvOS 10.0, tvOSApplicationExtension 10.0,
            watchOS 3.0, watchOSApplicationExtension 3.0, *) {
            queue.activate()
        }
    }
    
    public func suspend() {
        queue.suspend()
        isSuspended = true
    }
    
    public func resume() {
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
    
    public func addOperation(_ op: Operation) {
        op.addObserver(BlockObserver(produceHandler: { [weak self] in self?.addOperation($1) },
                                     finishHandler: { [weak self] in self?.operationFinished($0.0) }))
        operations.value.append(op)
        let dependencies = op.conditions.flatMap { $0.dependencyForOperation(op) }
        dependencies.forEach {
            op.addDependency($0)
            addOperation($0)
        }
        
        let concurrencyCategories: [String] = op.conditions.map { type(of: $0) }.filter { $0.isMutuallyExclusive }.map { String(describing: $0) }
        if !concurrencyCategories.isEmpty {
            ExclusivityController.addOperation(op, categories: concurrencyCategories)
            op.addObserver(BlockObserver(finishHandler: {
                ExclusivityController.removeOperation($0.0, categories: concurrencyCategories)
            }))
        }
        
        op.enqueue(on: queue)
    }
    
    private final func operationFinished(_ op: Operation) {
        _ = operations.value.index(where: { $0 === op }).map { operations.value.remove(at: $0) }
    }
    
    public func cancelAllOperations() {
        operations.value.forEach { $0.cancel() }
    }
}
