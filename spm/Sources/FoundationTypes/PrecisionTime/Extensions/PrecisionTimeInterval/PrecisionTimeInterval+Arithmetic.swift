import Foundation

extension PrecisionTimeInterval {

    // MARK: - Addition with Time Interval

    /// Add two time intervals with overflow clamping
    @inlinable
    public static func + (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Same sign: add magnitudes
        if lhs.sign == rhs.sign {
            return addMagnitudes(lhs: lhs, rhs: rhs, resultSign: lhs.sign)
        } else {
            // Different signs: subtract magnitudes
            return subtractMagnitudes(lhs: lhs, rhs: rhs)
        }
    }

    // MARK: - Helper Methods

    /// Add magnitudes of two intervals (assumes same sign)
    @inlinable
    internal static func addMagnitudes(
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval,
        resultSign: NumericSign
    ) -> PrecisionTimeInterval {
        // Add attoseconds first
        let (totalAttoseconds, attoOverflow) = lhs.attoseconds.addingReportingOverflow(rhs.attoseconds)

        // Add seconds
        let (totalSeconds, secondsOverflow) = lhs.seconds.addingReportingOverflow(rhs.seconds)

        // If either overflowed, clamp to max
        if secondsOverflow {
            return PrecisionTimeInterval(
                storage: SIMD2(UInt64.max, 0),
                sign: resultSign
            )
        }

        // If attoseconds overflowed, we need to add 1 to seconds
        if attoOverflow {
            let (finalSeconds, overflow) = totalSeconds.addingReportingOverflow(1)
            if overflow {
                return PrecisionTimeInterval(
                    storage: SIMD2(UInt64.max, 0),
                    sign: resultSign
                )
            }
            // Normalize will handle the totalAttoseconds (which wrapped)
            return PrecisionTimeInterval(
                storage: SIMD2(finalSeconds, totalAttoseconds),
                sign: resultSign
            )
        }

        // No overflow in either component - let normalize handle attoseconds > 1e18
        return PrecisionTimeInterval(
            storage: SIMD2(totalSeconds, totalAttoseconds),
            sign: resultSign
        )
    }

    /// Subtract magnitudes (lhs - rhs in terms of absolute values)
    @inlinable
    internal static func subtractMagnitudes(
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Compare magnitudes to determine which is larger
        let lhsGreater =
            (lhs.seconds > rhs.seconds) || (lhs.seconds == rhs.seconds && lhs.attoseconds >= rhs.attoseconds)

        if lhsGreater {
            // lhs >= rhs: result has lhs.sign
            return subtract(larger: lhs, smaller: rhs, resultSign: lhs.sign)
        } else {
            // rhs > lhs: result has rhs.sign
            return subtract(larger: rhs, smaller: lhs, resultSign: rhs.sign)
        }
    }

    /// Subtract smaller from larger (assumes larger >= smaller in magnitude)
    @inlinable
    internal static func subtract(
        larger: PrecisionTimeInterval,
        smaller: PrecisionTimeInterval,
        resultSign: NumericSign
    ) -> PrecisionTimeInterval {
        var resultSeconds = larger.seconds
        var resultAttoseconds = larger.attoseconds

        // Subtract attoseconds
        if larger.attoseconds >= smaller.attoseconds {
            resultAttoseconds = larger.attoseconds - smaller.attoseconds
        } else {
            // Borrow from seconds
            if resultSeconds > 0 {
                resultSeconds -= 1
                resultAttoseconds = (attosecondsPerSecond + larger.attoseconds) - smaller.attoseconds
            } else {
                // This shouldn't happen if larger >= smaller
                resultAttoseconds = 0
            }
        }

        // Subtract seconds
        resultSeconds = resultSeconds - smaller.seconds

        // Zero should always be positive (no negative zero)
        if resultSeconds == 0 && resultAttoseconds == 0 {
            return PrecisionTimeInterval(
                storage: SIMD2(0, 0),
                sign: .positive
            )
        }

        return PrecisionTimeInterval(
            storage: SIMD2(resultSeconds, resultAttoseconds),
            sign: resultSign
        )
    }

    /// Compound assignment addition
    @inlinable
    public static func += (lhs: inout PrecisionTimeInterval, rhs: PrecisionTimeInterval) {
        lhs = lhs + rhs
    }

    // MARK: - Subtraction

    /// Subtract two time intervals with overflow clamping
    @inlinable
    public static func - (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Subtract by adding the negation
        return lhs + (-rhs)
    }

    /// Compound assignment subtraction
    @inlinable
    public static func -= (lhs: inout PrecisionTimeInterval, rhs: PrecisionTimeInterval) {
        lhs = lhs - rhs
    }

    // MARK: - Unary Operators

    /// Negate a time interval (flip the sign)
    @inlinable
    public static prefix func - (operand: PrecisionTimeInterval) -> PrecisionTimeInterval {
        PrecisionTimeInterval(
            storage: operand.storage,
            sign: operand.sign == .positive ? .negative : .positive
        )
    }

    /// Unary plus (returns the value unchanged)
    @inlinable
    public static prefix func + (operand: PrecisionTimeInterval) -> PrecisionTimeInterval {
        operand
    }

    // MARK: - Wrapping Arithmetic

    /// Wrapping addition (allows overflow without clamping)
    @inlinable
    public static func &+ (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Same sign: add magnitudes with wrapping
        if lhs.sign == rhs.sign {
            // Add attoseconds and seconds with wrapping
            let totalAttoseconds = lhs.attoseconds &+ rhs.attoseconds
            let totalSeconds = lhs.seconds &+ rhs.seconds

            // Normalize without clamping (just wrapping)
            return PrecisionTimeInterval(
                storage: SIMD2(totalSeconds, totalAttoseconds),
                sign: lhs.sign
            )
        } else {
            // Different signs: use regular subtraction (no overflow possible)
            return subtractMagnitudes(lhs: lhs, rhs: rhs)
        }
    }

    /// Wrapping subtraction (allows overflow without clamping)
    @inlinable
    public static func &- (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Subtract by adding the negation with wrapping
        return lhs &+ (-rhs)
    }

    /// Compound assignment wrapping addition
    @inlinable
    public static func &+= (lhs: inout PrecisionTimeInterval, rhs: PrecisionTimeInterval) {
        lhs = lhs &+ rhs
    }

    /// Compound assignment wrapping subtraction
    @inlinable
    public static func &-= (lhs: inout PrecisionTimeInterval, rhs: PrecisionTimeInterval) {
        lhs = lhs &- rhs
    }
}
