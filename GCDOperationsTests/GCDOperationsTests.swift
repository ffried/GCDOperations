//
//  GCDOperationsTests.swift
//  GCDOperationsTests
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrfcih. All rights reserved.
//

import XCTest
@testable import GCDOperations

typealias Operation = GCDOperations.Operation
typealias BlockOperation = GCDOperations.BlockOperation
typealias OperationQueue = GCDOperations.OperationQueue

class GCDOperationsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOperation_WhenAddedToOperationQueue_Executes() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        let operation = BlockOperation {
            sleep(1)
            expectation.fulfill()
        }
        let queue = OperationQueue()
        
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 4) {
            XCTAssertNil($0)
//            XCTAssertEqual(operation.state, .finished(cancelled: false))
            XCTAssertTrue(operation.isFinished)
        }
    }
    
    func testOperation_WhenHavingDependencies_WaitsForDependencies() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        
        var op1Executed = false
        let operation1 = BlockOperation {
            sleep(1)
            op1Executed = true
            
        }
        var op1DidExecuteFirst = false
        let operation2 = BlockOperation {
            sleep(1)
            op1DidExecuteFirst = op1Executed
            expectation.fulfill()
        }
        operation2.addDependency(operation1)
        
        let queue = OperationQueue()
        
        queue.addOperation(operation2)
        queue.addOperation(operation1)
        
        waitForExpectations(timeout: 4) {
            XCTAssertNil($0)
            XCTAssertTrue(operation1.isFinished)
            XCTAssertTrue(operation2.isFinished)
//            XCTAssertEqual(operation1.state, .finished(cancelled: false))
//            XCTAssertEqual(operation2.state, .finished(cancelled: false))
            XCTAssertTrue(op1Executed)
            XCTAssertTrue(op1DidExecuteFirst)
        }
    }
}
