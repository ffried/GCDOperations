//
//  GroupOperation.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 04.04.17.
//  Copyright (c) 2017 Florian Friedrich. All rights reserved.
//

import Dispatch

public final class GroupOperation: Operation {

    private let group: DispatchGroup = DispatchGroup()

    public private(set) var operations: ContiguousArray<Operation>

    private weak var queue: DispatchQueue?

    public init(operations: ContiguousArray<Operation>) {
        self.operations = operations
    }

    public convenience init(operations: Operation...) {
        self.init(operations: ContiguousArray(operations))
    }

    public func addOperation(_ op: Operation) {
        precondition(!isFinished, "Cannot add operations after GroupOperation has finished!")
        operations.append(op)
        if state == .running, let queue = queue {
            includeOperation(op, on: queue)
        }
    }

    private final func includeOperation(_ op: Operation, on queue: DispatchQueue) {
        op.addObserver(BlockObserver(produceHandler: { [weak self] _, producedOp in self?.addOperation(producedOp) }))
        op.enqueue(on: queue, in: group)
    }

    internal override func enqueue(on queue: DispatchQueue, in group: DispatchGroup?) {
        self.queue = queue
        super.enqueue(on: queue, in: group)
    }

    public override func execute() {
        guard let queue = queue else { return finish() }
        operations.forEach { includeOperation($0, on: queue) }
        group.notify(queue: queue) { [unowned self] in
            guard !self.isCancelled else { return }
            self.finish()
        }
    }

    public override func didFinish() {
        super.didFinish()
        if isCancelled {
            // Cancel all operations that reside within us
            operations.forEach { $0.cancel() }
        }
    }

    override func cleanup() {
        super.cleanup()
        queue = nil
    }
}
