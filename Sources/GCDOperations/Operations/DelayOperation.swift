import Dispatch
import struct Foundation.Date
import typealias Foundation.TimeInterval
import typealias GCDCoreOperations.GCDOperation

/** 
 `DelayOperation` is an ``Operation`` that will simply wait for a given time
 interval, or until a specific `Date`.
 
 It is important to note that this operation does **not** use the `sleep()`
 function, since that is inefficient and blocks the thread on which it is called. 
 Instead, this operation uses `DispatchQueue.after` to know when the appropriate amount
 of time has passed.
 
 If the interval is negative, or the `Date` is in the past, then this operation
 immediately finishes.
*/
public final class DelayOperation: GCDOperation {
    private enum Delay {
        case interval(TimeInterval)
        case date(Date)

        var interval: TimeInterval {
            switch self {
            case .interval(let interval): return interval
            case .date(let date): return date.timeIntervalSinceNow
            }
        }
    }
    
    private let delay: Delay

    /// Creates a new delay operation, that delays for a given time interval.
    /// - Parameter interval: The interval to delay
    public init(interval: TimeInterval) {
        delay = .interval(interval)
        super.init()
    }

    /// Creates a new delay operation that delays until a given date.
    /// - Parameter date: The date until which to delay.
    public init(until date: Date) {
        delay = .date(date)
        super.init()
    }

    public override func execute() {
        let interval = delay.interval
        guard interval > 0 else {
            finish()
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            self.finish()
        }
    }
}
