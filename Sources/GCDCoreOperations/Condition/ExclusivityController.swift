@frozen
enum ExclusivityController {
    @Synchronized
    private static var operations: [String: ContiguousArray<Operation>] = [:]
    
    static func addOperation<Categories: Collection>(_ operation: Operation, categories: Categories)
    where Categories.Element == String
    {
        _operations.withValue { operations in
            categories.forEach {
                var operationsWithThisCategory = operations[$0, default: []]
                if let last = operationsWithThisCategory.last {
                    operation.addDependency(last)
                }
                operationsWithThisCategory.append(operation)
                operations[$0] = operationsWithThisCategory
            }
        }
    }
    
    static func removeOperation<Categories: Collection>(_ operation: Operation, categories: Categories)
    where Categories.Element == String
    {
        _operations.withValue { operations in
            categories.forEach {
                if var operationsWithThisCategory = operations[$0],
                   let index = operationsWithThisCategory.firstIndex(where: { $0 === operation }) {
                    operationsWithThisCategory.remove(at: index)
                    operations[$0] = operationsWithThisCategory
                }
            }
        }
    }
}
