import XCTest
@testable import GCDCoreOperations

final class OperationQueueTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCurrentQueue() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        var currentOperationQueue: GCDOperationQueue? = nil
        let operation = GCDBlockOperation {
            currentOperationQueue = .current
            $0([])
            expectation.fulfill()
        }
        let queue = GCDOperationQueue()
        queue.addOperation(operation)

        waitForExpectations(timeout: 2)
        XCTAssertTrue(operation.isFinished)
        XCTAssertNotNil(currentOperationQueue)
        XCTAssertTrue(currentOperationQueue === queue)
    }

    func testCurrentQueueOnMain() {
        let expectation = self.expectation(description: "Waiting for block to execute...")
        var currentOperationQueue: GCDOperationQueue? = nil

        DispatchQueue.main.async {
            currentOperationQueue = .current
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNotNil(currentOperationQueue)
        XCTAssertTrue(currentOperationQueue === GCDOperationQueue.main)
    }

    func testLifetimeWhileOperationsAreRunning() {
        let startExpectation = expectation(description: "Blocking op until queue has been set to nil")
        let opExpectation = expectation(description: "Waiting for operation to finish")
        var queue: GCDOperationQueue? = GCDOperationQueue()
        var testQueue: GCDOperationQueue?
        let blockOperation = GCDBlockOperation {
            self.wait(for: [startExpectation], timeout: 2)
            testQueue = .current
            $0([])
            opExpectation.fulfill()
        }
        queue?.addOperation(blockOperation)
        queue = nil // release
        startExpectation.fulfill()
        wait(for: [opExpectation], timeout: 2)
        XCTAssertNotNil(testQueue)
        XCTAssertFalse(testQueue === GCDOperationQueue.main)
    }

    func testDeinitializationWhenAllOperationsHaveCompleted() {
        final class _BlockOp: GCDOperation {
            let block: (_BlockOp) -> ()

            init(block: @escaping (_BlockOp) -> ()) {
                self.block = block
            }

            override func execute() {
                block(self)
                finish()
            }
        }
        let opExpectation = expectation(description: "Waiting for block to execute...")
        var queue: GCDOperationQueue? = GCDOperationQueue()
        var underlyingQueue: DispatchQueue?
        queue?.addOperation(_BlockOp {
            underlyingQueue = $0.queue
            opExpectation.fulfill()
        })
        queue = nil // release
        wait(for: [opExpectation], timeout: 2)
        XCTAssertNotNil(underlyingQueue)
        let queueExpectation = expectation(description: "Waiting for retrieval of queue.")
        var testQueue: GCDOperationQueue?
        // Note: we need to use async since otherwise we'll get the main queue.
        underlyingQueue?.async {
            testQueue = .current
            queueExpectation.fulfill()
        }
        wait(for: [queueExpectation], timeout: 2)
        XCTAssertNil(testQueue)
    }
}
