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

    func testDescription() {
        final class TestOp: GCDOperation {}

        let op1 = GCDOperation()
        let op2 = TestOp()
        op1.addDependency(op2)

        XCTAssertEqual(String(describing: op1), "\(GCDOperation.self)(state: \(op1.state))")
        XCTAssertEqual(String(describing: op2), "\(TestOp.self)(state: \(op2.state))")
        XCTAssertEqual(String(reflecting: op1), "\(GCDOperation.self)(state: \(op1.state), no. dependencies: 1, no. waiters: 0)")
        XCTAssertEqual(String(reflecting: op2), "\(TestOp.self)(state: \(op2.state), no. dependencies: 0, no. waiters: 0)")
    }
    
    func testSimpleExecution() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        let operation = GCDBlockOperation { sleep(1) }
        operation.addObserver(BlockObserver(finishHandler: { _, _, _ in
            expectation.fulfill()
        }))

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
        }
        var op1DidExecuteFirst = false
        let operation2 = GCDBlockOperation {
            sleep(1)
            op1DidExecuteFirst = op1Executed
        }
        operation2.addDependency(operation1)
        operation2.addObserver(BlockObserver(finishHandler: { _, _, _ in
            expectation.fulfill()
        }))
        
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
        let op1StartExpectation = expectation(description: "Waiting for op1 to start...")
        let finishExpectation = expectation(description: "Waiting for operations to execute...")

        let sema = DispatchSemaphore(value: 0)
        var op1Executed = false
        let operation1 = GCDBlockOperation { _ in // use async version
            op1Executed = true
            op1StartExpectation.fulfill()
            sema.wait()
        }
        var op1DidExecuteFirst = false
        let operation2 = GCDBlockOperation {
            op1DidExecuteFirst = op1Executed
        }
        let operation3 = GCDBlockOperation {}
        operation2.addDependency(operation1)
        operation3.addDependency(operation2)
        operation3.addObserver(BlockObserver(finishHandler: { _, _, _ in
            finishExpectation.fulfill()
        }))

        let queue = GCDOperationQueue()
        queue.addOperation(operation3)
        queue.addOperation(operation2)
        queue.addOperation(operation1)

        wait(for: [op1StartExpectation], timeout: 2)
        operation1.cancel()
        sema.signal()

        wait(for: [finishExpectation], timeout: 2)
        XCTAssertTrue(operation1.isFinished)
        XCTAssertTrue(operation2.isFinished)
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertFalse(operation2.isCancelled)
        XCTAssertTrue(op1Executed)
        XCTAssertTrue(op1DidExecuteFirst)
    }
}
