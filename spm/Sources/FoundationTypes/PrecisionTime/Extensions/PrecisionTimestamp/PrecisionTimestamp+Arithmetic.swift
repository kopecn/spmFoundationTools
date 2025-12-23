import Foundation

// MARK: - Arithmetic Operations
// Timestamp arithmetic operations delegate to PrecisionTimeInterval for consistency.
//
// Supported operations:
//   - Timestamp + Interval = Timestamp (advance/rewind time)
//   - Timestamp - Interval = Timestamp (rewind/advance time)
//   - Timestamp - Timestamp = Interval (duration between timestamps)
//   - Compound assignments: +=, -=

extension PrecisionTimestamp {

    // MARK: - Addition with Time Interval

    /// Add a time interval to a timestamp (move forward/backward in time)
    @inlinable
    public static func + (lhs: PrecisionTimestamp, rhs: PrecisionTimeInterval) -> PrecisionTimestamp {
        var result = lhs
        result.interval = lhs.interval + rhs
        return result
    }

    /// Add a time interval to a timestamp (move forward/backward in time)
    @inlinable
    public static func + (lhs: PrecisionTimeInterval, rhs: PrecisionTimestamp) -> PrecisionTimestamp {
        rhs + lhs
    }

    /// Compound assignment addition
    @inlinable
    public static func += (lhs: inout PrecisionTimestamp, rhs: PrecisionTimeInterval) {
        lhs.interval += rhs
    }

    // MARK: - Subtraction

    /// Subtract a time interval from a timestamp (move backward/forward in time)
    @inlinable
    public static func - (lhs: PrecisionTimestamp, rhs: PrecisionTimeInterval) -> PrecisionTimestamp {
        var result = lhs
        result.interval = lhs.interval - rhs
        return result
    }

    /// Compute the duration between two timestamps
    @inlinable
    public static func - (lhs: PrecisionTimestamp, rhs: PrecisionTimestamp) -> PrecisionTimeInterval {
        lhs.interval - rhs.interval
    }

    /// Compound assignment subtraction
    @inlinable
    public static func -= (lhs: inout PrecisionTimestamp, rhs: PrecisionTimeInterval) {
        lhs.interval -= rhs
    }

    // MARK: - Wrapping Arithmetic

    /// Wrapping addition (allows overflow without clamping)
    @inlinable
    public static func &+ (lhs: PrecisionTimestamp, rhs: PrecisionTimeInterval) -> PrecisionTimestamp {
        var result = lhs
        result.interval = lhs.interval &+ rhs
        return result
    }

    /// Wrapping addition (allows overflow without clamping)
    @inlinable
    public static func &+ (lhs: PrecisionTimeInterval, rhs: PrecisionTimestamp) -> PrecisionTimestamp {
        rhs &+ lhs
    }

    /// Compound assignment wrapping addition
    @inlinable
    public static func &+= (lhs: inout PrecisionTimestamp, rhs: PrecisionTimeInterval) {
        lhs.interval &+= rhs
    }

    /// Wrapping subtraction (allows overflow without clamping)
    @inlinable
    public static func &- (lhs: PrecisionTimestamp, rhs: PrecisionTimeInterval) -> PrecisionTimestamp {
        var result = lhs
        result.interval = lhs.interval &- rhs
        return result
    }

    /// Compound assignment wrapping subtraction
    @inlinable
    public static func &-= (lhs: inout PrecisionTimestamp, rhs: PrecisionTimeInterval) {
        lhs.interval &-= rhs
    }

    // MARK: - Unary Operators

    /// Negate a timestamp (flip sign: after epoch ↔ before epoch)
    /// Example: -timestamp(2025) → timestamp(1915) if epoch is 1970
    @inlinable
    public static prefix func - (operand: PrecisionTimestamp) -> PrecisionTimestamp {
        var result = operand
        result.interval = -operand.interval
        return result
    }

    /// Unary plus (returns the timestamp unchanged)
    @inlinable
    public static prefix func + (operand: PrecisionTimestamp) -> PrecisionTimestamp {
        operand
    }

    // MARK: - Generic Floating-Point Addition

    /// Add a floating-point time interval (in seconds) to a timestamp
    /// - Parameter add: Time interval in seconds (supports Double, Float, etc.)
    /// - Returns: A new timestamp advanced by the given interval
    ///
    /// Example:
    /// ```swift
    /// let timestamp = PrecisionTimestamp(seconds: 100)
    /// let result = timestamp.addingTimeInterval(add: 2.5) // Add 2.5 seconds
    /// ```
    @inlinable
    public func addingTimeInterval<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable>(
        add: T
    ) -> PrecisionTimestamp {
        // Convert floating-point seconds to PrecisionTimeInterval
        let absValue = abs(add)
        let sign: NumericSign = add >= 0 ? .positive : .negative

        // Split into seconds and fractional part
        let seconds = UInt64(absValue)
        let fractionalSeconds = absValue - T(seconds)
        let attoseconds = UInt64(fractionalSeconds * T(PrecisionTimeInterval.attosecondsPerSecond))

        // Create interval and use existing arithmetic
        let interval = PrecisionTimeInterval(
            seconds: seconds,
            attoseconds: attoseconds,
            sign: sign
        )

        return self + interval
    }
}
