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

    /// Add magnitudes of two intervals (same sign)
    @inlinable
    internal static func addMagnitudes(
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval,
        resultSign: NumericSign
    ) -> PrecisionTimeInterval {
        // In-place addition
        var totalSeconds = lhs.seconds
        var totalAttoseconds = lhs.attoseconds

        let attosSum = lhs.attoseconds + rhs.attoseconds
        let carry = attosSum / attosecondsPerSecond
        totalAttoseconds = attosSum % attosecondsPerSecond

        let (secondsSum, overflow) = lhs.seconds.addingReportingOverflow(rhs.seconds + carry)
        totalSeconds = overflow ? UInt64.max : secondsSum

        // Clamp to max if overflowed
        if overflow {
            totalAttoseconds = 0
        }

        return PrecisionTimeInterval(
            SIMD2(totalSeconds, totalAttoseconds),
            resultSign
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
            (lhs.seconds > rhs.seconds) || // Check escapes here if larger passes
            (lhs.seconds == rhs.seconds && lhs.attoseconds >= rhs.attoseconds)

        if lhsGreater {
            // lhs >= rhs: result has lhs.sign
            return subtractSmallerFromLarger(larger: lhs, smaller: rhs, resultSign: lhs.sign)
        } else {
            // rhs > lhs: result has rhs.sign
            return subtractSmallerFromLarger(larger: rhs, smaller: lhs, resultSign: rhs.sign)
        }
    }

    /// Subtract smaller from larger (assumes larger >= smaller in magnitude)
    @inlinable
    internal static func subtractSmallerFromLarger(
        larger: PrecisionTimeInterval,
        smaller: PrecisionTimeInterval,
        resultSign: NumericSign
    ) -> PrecisionTimeInterval {
        var resultSeconds = larger.seconds
        var resultAttoseconds = larger.attoseconds

        // Borrow if necessary
        if larger.attoseconds >= smaller.attoseconds {
            resultAttoseconds = larger.attoseconds - smaller.attoseconds
        } else {
            resultAttoseconds = (attosecondsPerSecond + larger.attoseconds) - smaller.attoseconds
            resultSeconds -= 1
        }

        resultSeconds -= smaller.seconds

        // Zero normalization
        if resultSeconds == 0 && resultAttoseconds == 0 {
            return PrecisionTimeInterval(
                SIMD2(0, 0),
                .positive
            )
        }

        return PrecisionTimeInterval(
            SIMD2(resultSeconds, resultAttoseconds),
            resultSign
        )
    }

    /// Compound assignment addition
    @inlinable
    public static func += (lhs: inout PrecisionTimeInterval, rhs: PrecisionTimeInterval) {
        lhs = lhs + rhs
    }

    // MARK: - Subtraction

    /// Subtract two time intervals
    @inlinable
    public static func - (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        return lhs + PrecisionTimeInterval(rhs.storage, rhs.sign.inverted)
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
            operand.storage,
            operand.sign == .positive ? .negative : .positive
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
                SIMD2(totalSeconds, totalAttoseconds),
                lhs.sign
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

    // MARK: - Generic Numeric Addition

    /// Add a numeric time interval (in seconds) to this interval
    /// - Parameter add: Time interval in seconds (supports any signed numeric type)
    /// - Returns: A new interval with the value added
    ///
    /// - Important: **Precision Warning** (for floating-point types)
    ///   This convenience method may introduce rounding errors when used with `BinaryFloatingPoint` types
    ///   due to limited floating-point precision. For maximum precision, use the standard
    ///   addition operator with a `PrecisionTimeInterval`:
    ///   ```swift
    ///   // Less precise (may lose attosecond precision):
    ///   let result = interval.addingTimeInterval(add: 3.14159)
    ///
    ///   // More precise (preserves full attosecond precision):
    ///   let addition = PrecisionTimeInterval(seconds: 3.14159)
    ///   let result = interval + addition
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
    /// let result1 = interval.addingTimeInterval(add: 3.14159) // Add pi seconds
    /// let result2 = interval.addingTimeInterval(add: 5)       // Add 5 seconds
    /// ```
    @inlinable
    public func addingTimeInterval<T: BinaryFloatingPoint>(
        add: T
    ) -> PrecisionTimeInterval {
        return self + PrecisionTimeInterval(seconds: add)
    }
    @inlinable
    public func addingTimeInterval<T: BinaryInteger>(
        add: T
    ) -> PrecisionTimeInterval {
        return self + PrecisionTimeInterval(seconds: add)
    }

    // MARK: - Multiplication

    /// Multiplies two UInt64 attosecond values, outputs result as seconds and attoseconds remainder
    @inlinable
    internal static func multiplyAttoseconds(
        _ a: UInt64,
        _ b: UInt64,
        resultSeconds: inout UInt64,
        resultAttoseconds: inout UInt64
    ) {

        // Split a and b into high and low 32-bit parts to avoid overflow
        let mask32: UInt64 = 0xFFFFFFFF
        let aLow = a & mask32
        let aHigh = a >> 32
        let bLow = b & mask32
        let bHigh = b >> 32

        // Multiply parts
        let lowLow = aLow * bLow                  // fits in 64-bit
        let lowHigh = aLow * bHigh
        let highLow = aHigh * bLow
        let highHigh = aHigh * bHigh

        // Combine partial products safely
        var total = lowLow
        var carry = total / Self.attosecondsPerSecond
        total = total % Self.attosecondsPerSecond

        // Add lowHigh shifted
        let lowHighShift = lowHigh << 32
        carry += lowHighShift / Self.attosecondsPerSecond
        total = (total + (lowHighShift % Self.attosecondsPerSecond)) % Self.attosecondsPerSecond

        // Add highLow shifted
        let highLowShift = highLow << 32
        carry += highLowShift / Self.attosecondsPerSecond
        total = (total + (highLowShift % Self.attosecondsPerSecond)) % Self.attosecondsPerSecond

        // Add highHigh shifted
        let highHighShift = highHigh << 64
        carry += highHighShift / Self.attosecondsPerSecond
        total = (total + (highHighShift % Self.attosecondsPerSecond)) % Self.attosecondsPerSecond

        resultSeconds = carry
        resultAttoseconds = total
    }


    /// Multiply two time intervals (for operations like time squared, time warping, etc.)
    /// - Parameters:
    ///   - lhs: The first time interval
    ///   - rhs: The second time interval
    /// - Returns: The product of the two intervals
    ///
    /// This operation is useful in physics calculations involving time squared,
    /// relativistic time dilation, or other scenarios where time intervals are multiplied.
    ///
    /// Example:
    /// ```swift
    /// let interval1 = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive)
    /// let interval2 = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// let product = interval1 * interval2 // 6 seconds (time squared in this case)
    /// ```
    @inlinable
    public static func * (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Handle zero cases
        if lhs.isZero || rhs.isZero {
            return .zero
        }

        var resultSeconds: UInt64 = lhs.seconds
        var resultAtto: UInt64 = lhs.attoseconds

        Self.multiplyAttoseconds(rhs.seconds, lhs.attoseconds, resultSeconds: &resultSeconds, resultAttoseconds: &resultAtto)

        let sign: NumericSign = lhs.sign == rhs.sign ? .positive : .negative

        return PrecisionTimeInterval(seconds: resultSeconds, attoseconds: resultAtto, sign: sign)
    }

    /// Compound assignment multiplication with PrecisionTimeInterval
    /// - Parameters:
    ///   - lhs: The time interval to modify
    ///   - rhs: The time interval multiplier
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// let multiplier = PrecisionTimeInterval(seconds: 3.0)
    /// interval *= multiplier // interval is now 6s
    /// ```
    @inlinable
    public static func *= (
        lhs: inout PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) {
        lhs = lhs * rhs
    }

    // MARK: - Scalar Multiplication

    /// Multiply a time interval by a floating-point scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The scalar multiplier
    /// - Returns: A new time interval scaled by the multiplier
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors
    ///   due to the limited precision of floating-point types. For maximum precision, convert your
    ///   scalar to `PrecisionTimeInterval` first and use interval-to-interval multiplication:
    ///   ```swift
    ///   // Less precise (may lose attosecond precision):
    ///   let result = interval * 2.5
    ///
    ///   // More precise (preserves full attosecond precision):
    ///   let multiplier = PrecisionTimeInterval(seconds: 2.5)
    ///   let result = interval * multiplier
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 2, attoseconds: 500_000_000_000_000_000, sign: .positive) // 2.5s
    /// let doubled = interval * 2.0 // 5.0s (but may have rounding errors)
    /// ```
    @available(*, deprecated, message: "BinaryFloatingPoint may lose precision. Prefer PrecisionTimeInterval.")
    @_disfavoredOverload
    @inlinable
    public static func * <T: BinaryFloatingPoint>(
        lhs: PrecisionTimeInterval,
        rhs: T
    ) -> PrecisionTimeInterval {
        // Handle zero
        guard rhs != 0 else {
            return .zero
        }

        return lhs * PrecisionTimeInterval(seconds: rhs)
    }

    /// Multiply a time interval by an integer scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The integer multiplier
    /// - Returns: A new time interval scaled by the multiplier
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 2, attoseconds: 500_000_000_000_000_000, sign: .positive) // 2.5s
    /// let tripled = interval * 3 // 7.5s
    /// ```
    @inlinable
    public static func * <T: BinaryInteger>(
        lhs: PrecisionTimeInterval,
        rhs: T
    ) -> PrecisionTimeInterval {
        // Handle zero
        guard rhs != 0 else {
            return .zero
        }
        return lhs * PrecisionTimeInterval(seconds: rhs)
    }

    /// Multiply a floating-point scalar value by a time interval (commutative)
    /// - Parameters:
    ///   - lhs: The scalar multiplier
    ///   - rhs: The time interval
    /// - Returns: A new time interval scaled by the multiplier
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors
    ///   due to the limited precision of floating-point types. For maximum precision, convert your
    ///   scalar to `PrecisionTimeInterval` first and use interval-to-interval multiplication:
    ///   ```swift
    ///   // Less precise (may lose attosecond precision):
    ///   let result = 3.0 * interval
    ///
    ///   // More precise (preserves full attosecond precision):
    ///   let multiplier = PrecisionTimeInterval(seconds: 3.0)
    ///   let result = multiplier * interval
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive) // 2s
    /// let tripled = 3.0 * interval // 6s (but may have rounding errors)
    /// ```
    @available(*, deprecated, message: "BinaryFloatingPoint may lose precision. Prefer PrecisionTimeInterval.")
    @_disfavoredOverload
    @inlinable
    public static func * <T: BinaryFloatingPoint>(
        lhs: T,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        return rhs * lhs
    }

    /// Multiply an integer scalar value by a time interval (commutative)
    /// - Parameters:
    ///   - lhs: The integer multiplier
    ///   - rhs: The time interval
    /// - Returns: A new time interval scaled by the multiplier
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive) // 2s
    /// let tripled = 3 * interval // 6s
    /// ```
    @inlinable
    public static func * <T: BinaryInteger>(
        lhs: T,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        return rhs * lhs
    }

    /// Compound assignment multiplication with floating-point scalar
    /// - Parameters:
    ///   - lhs: The time interval to modify
    ///   - rhs: The scalar multiplier
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors.
    ///   For maximum precision, convert your scalar to `PrecisionTimeInterval` first:
    ///   ```swift
    ///   // Less precise:
    ///   interval *= 1.5
    ///
    ///   // More precise:
    ///   let multiplier = PrecisionTimeInterval(seconds: 1.5)
    ///   interval *= multiplier
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// interval *= 1.5 // interval is now 3s (but may have rounding errors)
    /// ```
    @available(
        *,
        deprecated,
        message: "RHS: BinaryFloatingPoint may lose precision. Consider converting to PrecisionTimeInterval."
    )
    @_disfavoredOverload
    @inlinable
    public static func *= <T: BinaryFloatingPoint>(
        lhs: inout PrecisionTimeInterval,
        rhs: T
    ) {
        lhs = lhs * rhs
    }

    /// Compound assignment multiplication with integer scalar
    /// - Parameters:
    ///   - lhs: The time interval to modify
    ///   - rhs: The integer multiplier
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// interval *= 3 // interval is now 6s
    /// ```
    @inlinable
    public static func *= <T: BinaryInteger>(
        lhs: inout PrecisionTimeInterval,
        rhs: T
    ) {
        lhs = lhs * rhs
    }

    // MARK: - Scalar Division

    /// Divide a time interval by a floating-point scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The scalar divisor (must not be zero)
    /// - Returns: A new time interval divided by the scalar
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors
    ///   due to the limited precision of floating-point types. For maximum precision, convert your
    ///   scalar to `PrecisionTimeInterval` first and use the ratio operator:
    ///   ```swift
    ///   // Less precise (may lose attosecond precision):
    ///   let result = interval / 2.5
    ///
    ///   // More precise (preserves full attosecond precision):
    ///   let divisor = PrecisionTimeInterval(seconds: 2.5)
    ///   let ratio: Double = interval / divisor  // Get ratio as scalar
    ///   let result = interval * PrecisionTimeInterval(seconds: 1.0 / 2.5)
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive) // 10s
    /// let halved = interval / 2.0 // 5s (but may have rounding errors)
    /// ```
    // FIXME: - complete division at a later date
    // @available(*, deprecated, message: "BinaryFloatingPoint may lose precision. Prefer PrecisionTimeInterval.")
    // @_disfavoredOverload
    // @inlinable
    // public static func / <T: BinaryFloatingPoint>(
    //     lhs: PrecisionTimeInterval,
    //     rhs: T
    // ) -> PrecisionTimeInterval {
    //     // Convert interval to floating point, divide, and convert back
    //     let intervalSeconds: T = lhs.asFloatingPoint()
    //     let resultSeconds = intervalSeconds / rhs
    //     return PrecisionTimeInterval(seconds: resultSeconds)
    // }

    /// Divide a time interval by an integer scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The integer divisor (must not be zero)
    /// - Returns: A new time interval divided by the scalar
    ///
    /// - Note: Integer division may lose precision in the fractional part.
    ///   Consider using `BinaryFloatingPoint` if you need more precise division.
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive) // 10s
    /// let result = interval / 3 // 3.333... seconds
    /// ```
    // FIXME: - complete division at a later date
    // @inlinable
    // public static func / <T: BinaryInteger>(
    //     lhs: PrecisionTimeInterval,
    //     rhs: T
    // ) -> PrecisionTimeInterval {
    //     // Convert to PrecisionTimeInterval and use interval division
    //     let divisor = PrecisionTimeInterval(seconds: rhs)
    //     let ratio: Double = lhs / divisor
    //     return PrecisionTimeInterval(seconds: ratio)
    // }

    /// Compound assignment division with floating-point scalar
    /// - Parameters:
    ///   - lhs: The time interval to modify
    ///   - rhs: The scalar divisor (must not be zero)
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors.
    ///   For maximum precision, consider alternative approaches using `PrecisionTimeInterval`:
    ///   ```swift
    ///   // Less precise:
    ///   interval /= 3.0
    ///
    ///   // More precise:
    ///   let divisor = PrecisionTimeInterval(seconds: 3.0)
    ///   let ratio: Double = interval / divisor
    ///   interval = PrecisionTimeInterval(seconds: ratio / 3.0)
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 9, attoseconds: 0, sign: .positive)
    /// interval /= 3.0 // interval is now 3s (but may have rounding errors)
    /// ```
    // FIXME: - complete division at a later date
    // @available(
    //     *,
    //     deprecated,
    //     message: "BinaryFloatingPoint may lose precision. Consider converting to PrecisionTimeInterval."
    // )
    // @_disfavoredOverload
    // @inlinable
    // public static func /= <T: BinaryFloatingPoint>(
    //     lhs: inout PrecisionTimeInterval,
    //     rhs: T
    // ) {
    //     lhs = lhs / rhs
    // }

    /// Compound assignment division with integer scalar
    /// - Parameters:
    ///   - lhs: The time interval to modify
    ///   - rhs: The integer divisor (must not be zero)
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 9, attoseconds: 0, sign: .positive)
    /// interval /= 3 // interval is now 3s
    /// ```
    // FIXME: - complete division at a later date
    // @inlinable
    // public static func /= <T: BinaryInteger>(
    //     lhs: inout PrecisionTimeInterval,
    //     rhs: T
    // ) {
    //     lhs = lhs / rhs
    // }

    /// Divide a time interval by another time interval to get a scalar ratio
    /// - Parameters:
    ///   - lhs: The dividend time interval
    ///   - rhs: The divisor time interval
    /// - Returns: The ratio as a floating-point value
    ///
    /// Example:
    /// ```swift
    /// let interval1 = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
    /// let interval2 = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// let ratio: Double = interval1 / interval2 // 5.0
    /// ```
    // FIXME: - complete division at a later date
    // @inlinable
    // public static func / <T: BinaryFloatingPoint>(
    //     lhs: PrecisionTimeInterval,
    //     rhs: PrecisionTimeInterval
    // ) -> T {
    //     let lhsSeconds: T = lhs.asFloatingPoint()
    //     let rhsSeconds: T = rhs.asFloatingPoint()
    //     return lhsSeconds / rhsSeconds
    // }
}
