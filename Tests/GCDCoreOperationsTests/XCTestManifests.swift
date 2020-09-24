#if !canImport(ObjectiveC)
import XCTest

extension GCDCoreOperationsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__GCDCoreOperationsTests = [
        ("testOperation_WhenAddedToOperationQueue_Executes", testOperation_WhenAddedToOperationQueue_Executes),
        ("testOperation_WhenHavingDependencies_WaitsForDependencies", testOperation_WhenHavingDependencies_WaitsForDependencies),
        ("testOperationQueue_WhenAccessingCurrentQueue_ReturnsCurrentQueue", testOperationQueue_WhenAccessingCurrentQueue_ReturnsCurrentQueue),
        ("testOperationQueue_WhenAccessingCurrentQueueAfterQueueWasDestroyed_ReturnsNil", testOperationQueue_WhenAccessingCurrentQueueAfterQueueWasDestroyed_ReturnsNil),
        ("testOperationQueue_WhenAccessingCurrentQueueOnMainThread_ReturnsMainQueue", testOperationQueue_WhenAccessingCurrentQueueOnMainThread_ReturnsMainQueue),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GCDCoreOperationsTests.__allTests__GCDCoreOperationsTests),
    ]
}
#endif