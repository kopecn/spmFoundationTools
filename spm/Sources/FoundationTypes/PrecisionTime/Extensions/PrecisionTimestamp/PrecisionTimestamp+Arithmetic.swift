import Foundation


// MARK: - Arithmetic Operations
// Plan to add:
//      +, =+, -, =-, duration, for both lhs / rhs, with time interval
//      TimeStamp (+/-, =+/=-) TimeInterval = TimeStamp
//      TimeStamp - TimeStamp = TimeInterval
//      
//      
//      


extension PrecisionTimestamp {

    // MARK: - Addition with Time Interval

    /// Add a time interval to a timestamp
    @inlinable
    public static func + (lhs: PrecisionTimestamp, rhs: PrecisionTimeInterval) -> PrecisionTimestamp {

        var result = lhs

        switch rhs.sign {
            case .zero:
                return result
            case .positive:
                result.storage = lhs.storage &+ rhs.storage

                // handle attosecond wrap
                if result.attoseconds > Self.attosecondsPerSecond {
                    result.seconds = result.seconds + 1
                    result.attoseconds = result.attoseconds - Self.attosecondsPerSecond
                }

                // If we wrapped seconds return the clamped to max
                if result.seconds < lhs.seconds {
                    result.storage = SIMD2(UInt64.max,0)
                    return result
                }

                return result

            case .negative:

                // decrement seconds and bump attoseconds if attoseconds will wrap
                if lhs.attoseconds < rhs.attoseconds {
                    result.seconds = result.seconds - 1
                    result.attoseconds = result.attoseconds + Self.attosecondsPerSecond
                }

                result.storage = lhs.storage &- rhs.storage

                if result.seconds > lhs.seconds {
                    result.storage = SIMD2(0,0)
                    return result
                }

                if result.seconds <= lhs.seconds && result.attoseconds < Self.attosecondsPerSecond {
                    // Happy Path fast escape hatch
                    return result
                }

                return result
        }
    }
}
