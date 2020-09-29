import XCTest
@testable import GCDCoreOperations

final class OperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleExecution() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        let operation = GCDBlockOperation {
            defer { expectation.fulfill() }
            sleep(1)
            $0([])
        }

        let queue = GCDOperationQueue()
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 4)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testWaitingForDependencies() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        
        var op1Executed = false
        let operation1 = GCDBlockOperation {
            sleep(1)
            op1Executed = true
            $0([])
        }
        var op1DidExecuteFirst = false
        let operation2 = GCDBlockOperation {
            sleep(1)
            op1DidExecuteFirst = op1Executed
            $0([])
            expectation.fulfill()
        }
        operation2.addDependency(operation1)
        
        let queue = GCDOperationQueue()
        queue.addOperation(operation2)
        queue.addOperation(operation1)
        
        waitForExpectations(timeout: 4)
        XCTAssertTrue(operation1.isFinished)
        XCTAssertTrue(operation2.isFinished)
        XCTAssertFalse(operation1.isCancelled)
        XCTAssertFalse(operation2.isCancelled)
        XCTAssertTrue(op1Executed)
        XCTAssertTrue(op1DidExecuteFirst)
    }

    func testWaitingForDependenciesWhichAreCancelled() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")

        var op1Executed = false
        let operation1 = GCDBlockOperation {
            sleep(1)
            op1Executed = true
            $0([])
        }
        var op1DidExecuteFirst = false
        let operation2 = GCDBlockOperation {
            sleep(1)
            op1DidExecuteFirst = op1Executed
            $0([])
            expectation.fulfill()
        }
        operation2.addDependency(operation1)

        let queue = GCDOperationQueue()
        queue.addOperation(operation2)
        queue.addOperation(operation1)

        operation1.cancel()

        waitForExpectations(timeout: 4)
        XCTAssertTrue(operation1.isFinished)
        XCTAssertTrue(operation2.isFinished)
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertFalse(operation2.isCancelled)
        XCTAssertFalse(op1Executed)
        XCTAssertFalse(op1DidExecuteFirst)
    }
}
