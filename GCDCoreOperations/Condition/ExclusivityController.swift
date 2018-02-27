//
//  ExclusivityController.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class Dispatch.DispatchQueue

internal struct ExclusivityController {
    // No instances necessary
    private init() {}
    
    private static let serialQueue = DispatchQueue(label: "net.ffried.GCDOperations.ExclusivityController.Lock")
    private static var operations: [String: [Operation]] = [:]
    
    static func addOperation(_ operation: Operation, categories: [String]) {
        serialQueue.sync {
            categories.forEach { _unsafeAddOperation(operation, category: $0) }
        }
    }
    
    static func removeOperation(_ operation: Operation, categories: [String]) {
        serialQueue.async {
            categories.forEach { _unsafeRemoveOperation(operation, category: $0) }
        }
    }
    
    private static func _unsafeAddOperation(_ operation: Operation, category: String) {
        var operationsWithThisCategory = operations[category] ?? []
        
        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }
        
        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }
    
    private static func _unsafeRemoveOperation(_ operation: Operation, category: String) {
        if var operationsWithThisCategory = operations[category],
            let index = operationsWithThisCategory.index(where: { $0 === operation}) {

            operationsWithThisCategory.remove(at: index)
            operations[category] = operationsWithThisCategory
        }
    }
}
