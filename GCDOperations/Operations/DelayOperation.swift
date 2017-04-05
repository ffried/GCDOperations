//
//  DelayOperation.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import struct Foundation.Date
import typealias Foundation.TimeInterval

/** 
    `DelayOperation` is an `Operation` that will simply wait for a given time 
    interval, or until a specific `NSDate`.

    It is important to note that this operation does **not** use the `sleep()`
    function, since that is inefficient and blocks the thread on which it is called. 
    Instead, this operation uses `DispatchQueue.after` to know when the appropriate amount
    of time has passed.

    If the interval is negative, or the `Date` is in the past, then this operation
    immediately finishes.
*/
public final class DelayOperation: GCDCoreOperations.Operation {
    // MARK: Types
    private enum Delay {
        case interval(TimeInterval)
        case date(Date)
    }
    
    // MARK: Properties
    private let delay: Delay
    
    // MARK: Initialization
    public init(interval: TimeInterval) {
        delay = .interval(interval)
        super.init()
    }
    
    public init(until date: Date) {
        delay = .date(date)
        super.init()
    }
    
    override open func execute() {
        let interval: TimeInterval
        
        // Figure out how long we should wait for.
        switch delay {
            case .interval(let theInterval):
                interval = theInterval
            case .date(let date):
                interval = date.timeIntervalSinceNow
        }
        
        guard interval > 0 else {
            finish()
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
            // If we were cancelled, then finish() has already been called.
            if !self.isCancelled {
                self.finish()
            }
        }
    }
}
