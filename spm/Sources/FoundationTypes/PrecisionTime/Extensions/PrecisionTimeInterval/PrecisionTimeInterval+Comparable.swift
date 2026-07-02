import Foundation

// MARK: - Comparable

extension PrecisionTimeInterval: Comparable {
    public static func < (lhs: PrecisionTimeInterval, rhs: PrecisionTimeInterval) -> Bool {
        // Handle different signs: negative < zero < positive
        if lhs.sign != rhs.sign {
            switch (lhs.sign, rhs.sign) {
            case (.negative, .zero), (.negative, .positive), (.zero, .positive):
                return true
            case (.zero, .negative), (.positive, .negative), (.positive, .zero):
                return false
            default:
                // Same sign, continue to magnitude comparison
                break
            }
        }

        // If either is zero, check if both are truly zero
        if lhs.sign == .zero || rhs.sign == .zero {
            // Zero values should have seconds == 0 and attoseconds == 0
            let lhsIsZero = (lhs.seconds == 0 && lhs.attoseconds == 0)
            let rhsIsZero = (rhs.seconds == 0 && rhs.attoseconds == 0)

            if lhsIsZero && rhsIsZero {
                return false  // Equal values
            } else if lhsIsZero {
                return rhs.sign == .positive  // 0 < positive
            } else if rhsIsZero {
                return lhs.sign == .negative  // negative < 0
            }
        }

        // Same sign - compare magnitudes
        if lhs.seconds != rhs.seconds {
            let secondsLess = lhs.seconds < rhs.seconds
            // If positive, normal comparison; if negative, reverse
            return lhs.sign == .positive ? secondsLess : !secondsLess
        }

        // Seconds are equal, compare attoseconds
        let attosecondsLess = lhs.attoseconds < rhs.attoseconds
        // If positive, normal comparison; if negative, reverse
        return lhs.sign == .positive ? attosecondsLess : !attosecondsLess
    }
}

// MARK: - Zero Check

extension PrecisionTimeInterval {

    /// Check if this interval is zero
    @inlinable
    public var isZero: Bool {
        return sign == .zero
    }

    /// Check if this interval is positive (> 0)
    @inlinable
    public var isPositive: Bool {
        return sign == .positive
    }

    /// Check if this interval is negative (< 0)
    @inlinable
    public var isNegative: Bool {
        return sign == .negative
    }

    /// A zero time interval
    @inlinable
    public static var zero: PrecisionTimeInterval {
        return PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
    }
}
