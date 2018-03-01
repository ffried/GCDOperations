//
//  DelayOperation.swift
//  GCDOperations
//
//  Created by Florian Friedrich on 02.04.17.
//  Copyright © 2017 Florian Friedrich. All rights reserved.
//

import struct Foundation.Date
import typealias Foundation.TimeInterval
import class GCDCoreOperations.Operation

/** 
    `DelayOperation` is an `Operation` that will simply wait for a given time 
    interval, or until a specific `Date`.

    It is important to note that this operation does **not** use the `sleep()`
    function, since that is inefficient and blocks the thread on which it is called. 
    Instead, this operation uses `DispatchQueue.after` to know when the appropriate amount
    of time has passed.

    If the interval is negative, or the `Date` is in the past, then this operation
    immediately finishes.
*/
public final class DelayOperation: GCDCoreOperations.Operation {
    private enum Delay {
        case interval(TimeInterval)
        case date(Date)

        var internval: TimeInterval {
            switch self {
            case .interval(let inverval): return interval
            case .date(let date): return date.timeIntervalSinceNow
            }
        }
    }
    
    private let delay: Delay
    
    public init(interval: TimeInterval) {
        delay = .interval(interval)
        super.init()
    }
    
    public init(until date: Date) {
        delay = .date(date)
        super.init()
    }
    
    override open func execute() {
        let interval = delay.interval
        guard interval > 0 else {
            finish()
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
            guard !self.isCancelled else { return }
            self.finish()
        }
    }
}
