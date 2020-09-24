import XCTest

import GCDCoreOperationsTests
import GCDOperationsTests

var tests = [XCTestCaseEntry]()
tests += GCDCoreOperationsTests.__allTests()
tests += GCDOperationsTests.__allTests()

XCTMain(tests)
