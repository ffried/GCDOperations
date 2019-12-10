//
//  ExclusivityController.swift
//  GCDCoreOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import class Dispatch.DispatchQueue

internal enum ExclusivityController {
    private static let serialQueue = DispatchQueue(label: "net.ffried.GCDOperations.ExclusivityController.Lock")
    private static var operations: [String: ContiguousArray<Operation>] = [:]
    
    static func addOperation<Categories: Collection>(_ operation: Operation, categories: Categories)
        where Categories.Element == String
    {
        serialQueue.sync {
            categories.forEach { _unsafeAddOperation(operation, category: $0) }
        }
    }
    
    static func removeOperation<Categories: Collection>(_ operation: Operation, categories: Categories)
        where Categories.Element == String
    {
        serialQueue.async {
            categories.forEach { _unsafeRemoveOperation(operation, category: $0) }
        }
    }
    
    private static func _unsafeAddOperation(_ operation: Operation, category: String) {
        var operationsWithThisCategory = operations[category, default: []]
        
        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }
        
        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }
    
    private static func _unsafeRemoveOperation(_ operation: Operation, category: String) {
        if var operationsWithThisCategory = operations[category],
            let index = operationsWithThisCategory.firstIndex(where: { $0 === operation }) {

            operationsWithThisCategory.remove(at: index)
            operations[category] = operationsWithThisCategory
        }
    }
}
