//
//  GCDCoreOperationsTests.swift
//  GCDCoreOperationsTests
//
//  Created by Florian Friedrich on 05.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import XCTest
@testable import GCDCoreOperations

typealias Operation = GCDCoreOperations.Operation
typealias OperationQueue = GCDCoreOperations.OperationQueue

final class GCDCoreOperationsTests: XCTestCase {
    
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
            $0([])
        }
        let queue = OperationQueue()
        
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 4) {
            XCTAssertNil($0)
            XCTAssertTrue(operation.isFinished)
            XCTAssertFalse(operation.isCancelled)
        }
    }
    
    func testOperation_WhenHavingDependencies_WaitsForDependencies() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        
        var op1Executed = false
        let operation1 = BlockOperation {
            sleep(1)
            op1Executed = true
            $0([])
        }
        var op1DidExecuteFirst = false
        let operation2 = BlockOperation {
            sleep(1)
            op1DidExecuteFirst = op1Executed
            expectation.fulfill()
            $0([])
        }
        operation2.addDependency(operation1)
        
        let queue = OperationQueue()
        
        queue.addOperation(operation2)
        queue.addOperation(operation1)
        
        waitForExpectations(timeout: 4) {
            XCTAssertNil($0)
            XCTAssertTrue(operation1.isFinished)
            XCTAssertTrue(operation2.isFinished)
            XCTAssertFalse(operation1.isCancelled)
            XCTAssertFalse(operation2.isCancelled)
            XCTAssertTrue(op1Executed)
            XCTAssertTrue(op1DidExecuteFirst)
        }
    }
    
    func testOperationQueue_WhenAccessingCurrentQueue_ReturnsCurrentQueue() {
        let expectation = self.expectation(description: "Waiting for Operation to execute...")
        var currentOperationQueue: OperationQueue? = nil
        let operation = BlockOperation {
            currentOperationQueue = .current
            expectation.fulfill()
            $0([])
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 2) {
            XCTAssertNil($0)
            XCTAssertTrue(operation.isFinished)
            XCTAssertNotNil(currentOperationQueue)
            XCTAssertTrue(currentOperationQueue === queue)
        }
    }
    
    func testOperationQueue_WhenAccessingCurrentQueueOnMainThread_ReturnsMainQueue() {
        let expectation = self.expectation(description: "Waiting for block to execute...")
        var currentOperationQueue: OperationQueue? = nil
        
        DispatchQueue.main.async {
            currentOperationQueue = .current
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) {
            XCTAssertNil($0)
            XCTAssertNotNil(currentOperationQueue)
            XCTAssertTrue(currentOperationQueue === OperationQueue.main)
        }
    }
}
