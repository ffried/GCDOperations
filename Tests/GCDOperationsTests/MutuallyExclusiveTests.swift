import XCTest
@testable import GCDOperations

final class MutuallyExclusiveTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMutuallyExclusiveCondition() {
        enum MutTarget {}
        let expectation = self.expectation(description: "Waiting for op1 to complete")
        var op1IsRunning = false
        var op1WasRunning = true
        var op2IsRunning = false
        var op2WasRunning = true
        let op1 = GCDBlockOperation { completion in
            op1IsRunning = true
            defer { op1IsRunning = false }
            op2WasRunning = op2IsRunning
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                completion([])
            }
        }
        op1.addCondition(MutuallyExclusive<MutTarget>())
        let op2 = GCDBlockOperation {
            op2IsRunning = true
            defer { op2IsRunning = false }
            op1WasRunning = op1IsRunning
            expectation.fulfill()
            $0([])
        }
        op2.addCondition(MutuallyExclusive<MutTarget>())
        let queue = GCDOperationQueue()
        queue.addOperations(op1, op2)
        waitForExpectations(timeout: 2)
        XCTAssertFalse(op1WasRunning)
        XCTAssertFalse(op2WasRunning)
    }
}
