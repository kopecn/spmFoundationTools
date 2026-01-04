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

    /// Divides a 128-bit number (high * 2^64 + low) by a 64-bit divisor
    /// Returns (quotient, remainder)
    @inlinable
    internal static func divide128By64(
        high: UInt64,
        low: UInt64,
        by divisor: UInt64
    ) -> (quotient: UInt64, remainder: UInt64) {
        // Handle simple case where high fits in the quotient range
        let highQuotient = high / divisor
        let highRemainder = high % divisor

        // Now divide (highRemainder * 2^64 + low) by divisor
        // Use double-precision division approximation with correction
        if highRemainder == 0 {
            return (highQuotient + low / divisor, low % divisor)
        }

        // For highRemainder * 2^64 + low, we need careful handling
        // Use the identity: 2^64 = q*divisor + r where q and r are precomputed
        // For divisor = 10^18: 2^64 = 18 * 10^18 + 446744073709551616
        let twoTo64DivDivisor: UInt64 = (divisor == Self.attosecondsPerSecond)
            ? 18
            : UInt64.max / divisor + 1
        let twoTo64ModDivisor: UInt64 = (divisor == Self.attosecondsPerSecond)
            ? 446_744_073_709_551_616
            : (UInt64.max % divisor) + 1

        let quotientFromHigh = highRemainder * twoTo64DivDivisor

        // Now handle (highRemainder * twoTo64ModDivisor + low) / divisor
        let (prodHigh, prodLow) = highRemainder.multipliedFullWidth(by: twoTo64ModDivisor)
        let (sumLow, carry) = prodLow.addingReportingOverflow(low)
        let sumHigh = prodHigh &+ (carry ? 1 : 0)

        // Recursively divide if needed, but typically sumHigh is small
        let (extraQuotient, finalRemainder) = sumHigh == 0
            ? (sumLow / divisor, sumLow % divisor)
            : divide128By64(high: sumHigh, low: sumLow, by: divisor)

        return (highQuotient + quotientFromHigh + extraQuotient, finalRemainder)
    }

    /// Multiplies two UInt64 values, outputs result divided by attosecondsPerSecond
    /// Returns quotient in resultSeconds and remainder in resultAttoseconds
    @inlinable
    internal static func multiplyAttoseconds(
        _ a: UInt64,
        _ b: UInt64,
        resultSeconds: inout UInt64,
        resultAttoseconds: inout UInt64
    ) {
        // Use Swift's built-in full-width multiplication to get the 128-bit result
        let (high, low) = a.multipliedFullWidth(by: b)

        // Divide the 128-bit result by attosecondsPerSecond
        let (quotient, remainder) = divide128By64(
            high: high,
            low: low,
            by: Self.attosecondsPerSecond
        )

        resultSeconds = quotient
        resultAttoseconds = remainder
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

        var totalSeconds: UInt64 = 0
        var totalAttoseconds: UInt64 = 0

        // Product 1: lhs.seconds * rhs.seconds (direct seconds contribution)
        let (secProduct, overflow1) = lhs.seconds.multipliedReportingOverflow(by: rhs.seconds)
        if overflow1 {
            // Overflow - return max value
            return PrecisionTimeInterval(SIMD2(UInt64.max, 0), lhs.sign == rhs.sign ? .positive : .negative)
        }
        totalSeconds = secProduct

        // Product 2: lhs.seconds * rhs.attoseconds (result in attoseconds)
        var tempSeconds: UInt64 = 0
        var tempAttoseconds: UInt64 = 0
        Self.multiplyAttoseconds(lhs.seconds, rhs.attoseconds, resultSeconds: &tempSeconds, resultAttoseconds: &tempAttoseconds)
        let (sum1, overflow2) = totalSeconds.addingReportingOverflow(tempSeconds)
        if overflow2 {
            return PrecisionTimeInterval(SIMD2(UInt64.max, 0), lhs.sign == rhs.sign ? .positive : .negative)
        }
        totalSeconds = sum1
        totalAttoseconds = totalAttoseconds &+ tempAttoseconds

        // Product 3: lhs.attoseconds * rhs.seconds (result in attoseconds)
        Self.multiplyAttoseconds(lhs.attoseconds, rhs.seconds, resultSeconds: &tempSeconds, resultAttoseconds: &tempAttoseconds)
        let (sum2, overflow3) = totalSeconds.addingReportingOverflow(tempSeconds)
        if overflow3 {
            return PrecisionTimeInterval(SIMD2(UInt64.max, 0), lhs.sign == rhs.sign ? .positive : .negative)
        }
        totalSeconds = sum2
        totalAttoseconds = totalAttoseconds &+ tempAttoseconds

        // Product 4: lhs.attoseconds * rhs.attoseconds (result in 10^-36 seconds)
        Self.multiplyAttoseconds(lhs.attoseconds, rhs.attoseconds, resultSeconds: &tempSeconds, resultAttoseconds: &tempAttoseconds)
        // tempSeconds is in attoseconds, tempAttoseconds is sub-attosecond precision (can be ignored)
        totalAttoseconds = totalAttoseconds &+ tempSeconds

        // Normalize: carry attoseconds to seconds
        let carry = totalAttoseconds / attosecondsPerSecond
        totalAttoseconds = totalAttoseconds % attosecondsPerSecond
        let (finalSeconds, overflow4) = totalSeconds.addingReportingOverflow(carry)
        if overflow4 {
            return PrecisionTimeInterval(SIMD2(UInt64.max, 0), lhs.sign == rhs.sign ? .positive : .negative)
        }
        totalSeconds = finalSeconds

        let sign: NumericSign = lhs.sign == rhs.sign ? .positive : .negative

        return PrecisionTimeInterval(seconds: totalSeconds, attoseconds: totalAttoseconds, sign: sign)
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

    /// Helper function to divide a PrecisionTimeInterval by a UInt64 scalar with full precision
    /// - Parameters:
    ///   - interval: The time interval to divide
    ///   - divisor: The UInt64 divisor (must not be zero)
    /// - Returns: A new time interval divided by the scalar
    @inlinable
    internal static func divideByScalar(
        _ interval: PrecisionTimeInterval,
        _ divisor: UInt64
    ) -> PrecisionTimeInterval {
        guard divisor != 0 else {
            // Division by zero - return max value with same sign
            return PrecisionTimeInterval(
                SIMD2(UInt64.max, 0),
                interval.sign
            )
        }

        // Handle zero interval
        if interval.isZero {
            return .zero
        }

        // Step 1: Divide seconds by divisor
        let quotientSeconds = interval.seconds / divisor
        let remainderSeconds = interval.seconds % divisor

        // Step 2: Convert remainder seconds to attoseconds and add interval.attoseconds
        // This creates a 128-bit number: remainderSeconds * 10^18 + interval.attoseconds
        let (high, low) = remainderSeconds.multipliedFullWidth(by: Self.attosecondsPerSecond)

        // Add interval.attoseconds to the low part
        let (sumLow, carry) = low.addingReportingOverflow(interval.attoseconds)
        let sumHigh = high &+ (carry ? 1 : 0)

        // Step 3: Divide this 128-bit number by divisor to get attoseconds quotient
        let (quotientAttoseconds, _) = divide128By64(
            high: sumHigh,
            low: sumLow,
            by: divisor
        )

        return PrecisionTimeInterval(
            SIMD2(quotientSeconds, quotientAttoseconds),
            interval.sign
        )
    }

    /// Divide a time interval by a floating-point scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The scalar divisor (must not be zero)
    /// - Returns: A new time interval divided by the scalar
    ///
    /// - Important: **Precision Warning**
    ///   This operation converts through `BinaryFloatingPoint`, which may introduce rounding errors
    ///   due to the limited precision of floating-point types. For maximum precision, convert your
    ///   scalar to `PrecisionTimeInterval` first and use interval-to-interval division:
    ///   ```swift
    ///   // Less precise (may lose attosecond precision):
    ///   let result = interval / 2.5
    ///
    ///   // More precise (preserves full attosecond precision):
    ///   let divisor = PrecisionTimeInterval(seconds: 2.5)
    ///   let result = interval / divisor
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive) // 10s
    /// let halved = interval / 2.0 // 5s (but may have rounding errors)
    /// ```
    @available(*, deprecated, message: "BinaryFloatingPoint may lose precision. Prefer PrecisionTimeInterval.")
    @_disfavoredOverload
    @inlinable
    public static func / <T: BinaryFloatingPoint>(
        lhs: PrecisionTimeInterval,
        rhs: T
    ) -> PrecisionTimeInterval {
        // Convert scalar to PrecisionTimeInterval and use interval division
        let divisor = PrecisionTimeInterval(seconds: rhs)
        return lhs / divisor
    }

    /// Divide a time interval by an integer scalar value
    /// - Parameters:
    ///   - lhs: The time interval
    ///   - rhs: The integer divisor (must not be zero)
    /// - Returns: A new time interval divided by the scalar
    ///
    /// Example:
    /// ```swift
    /// let interval = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive) // 10s
    /// let result = interval / 3 // 3.333... seconds with full attosecond precision
    /// ```
    @inlinable
    public static func / <T: BinaryInteger>(
        lhs: PrecisionTimeInterval,
        rhs: T
    ) -> PrecisionTimeInterval {
        // Convert to UInt64 and use the helper function
        let divisor = UInt64(rhs.magnitude)
        let result = divideByScalar(lhs, divisor)

        // Handle negative divisor (flip sign)
        if rhs < 0 {
            return PrecisionTimeInterval(result.storage, result.sign.inverted)
        }
        return result
    }

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
    ///   interval = interval / divisor
    ///   ```
    ///
    /// Example:
    /// ```swift
    /// var interval = PrecisionTimeInterval(seconds: 9, attoseconds: 0, sign: .positive)
    /// interval /= 3.0 // interval is now 3s (but may have rounding errors)
    /// ```
    @available(
        *,
        deprecated,
        message: "BinaryFloatingPoint may lose precision. Consider converting to PrecisionTimeInterval."
    )
    @_disfavoredOverload
    @inlinable
    public static func /= <T: BinaryFloatingPoint>(
        lhs: inout PrecisionTimeInterval,
        rhs: T
    ) {
        lhs = lhs / rhs
    }

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
    @inlinable
    public static func /= <T: BinaryInteger>(
        lhs: inout PrecisionTimeInterval,
        rhs: T
    ) {
        lhs = lhs / rhs
    }

    // MARK: - Interval Division

    /// Divide a time interval by another time interval
    /// - Parameters:
    ///   - lhs: The dividend time interval
    ///   - rhs: The divisor time interval
    /// - Returns: A new time interval representing the quotient
    ///
    /// This operation computes lhs / rhs as a time interval. The result represents
    /// how many times rhs fits into lhs, expressed as a dimensionless time interval.
    ///
    /// Example:
    /// ```swift
    /// let interval1 = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
    /// let interval2 = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
    /// let quotient = interval1 / interval2 // 5.0 seconds (dimensionless)
    /// ```
    @inlinable
    public static func / (
        lhs: PrecisionTimeInterval,
        rhs: PrecisionTimeInterval
    ) -> PrecisionTimeInterval {
        // Handle zero divisor
        guard !rhs.isZero else {
            return PrecisionTimeInterval(
                SIMD2(UInt64.max, 0),
                lhs.sign == rhs.sign ? .positive : .negative
            )
        }

        // Handle zero dividend
        if lhs.isZero {
            return .zero
        }

        // Convert both intervals to total attoseconds (as 128-bit numbers)
        // lhs: lhs.seconds * 10^18 + lhs.attoseconds
        // rhs: rhs.seconds * 10^18 + rhs.attoseconds

        // For division, we need to compute: (lhs_total_attos) / (rhs_total_attos)
        // This gives us a dimensionless ratio

        // First, compute lhs in total attoseconds (128-bit)
        let (lhsHigh, lhsLow) = lhs.seconds.multipliedFullWidth(by: Self.attosecondsPerSecond)
        let (lhsSumLow, lhsCarry) = lhsLow.addingReportingOverflow(lhs.attoseconds)
        let lhsSumHigh = lhsHigh &+ (lhsCarry ? 1 : 0)

        // Compute rhs in total attoseconds (128-bit)
        let (rhsHigh, rhsLow) = rhs.seconds.multipliedFullWidth(by: Self.attosecondsPerSecond)
        let (rhsSumLow, rhsCarry) = rhsLow.addingReportingOverflow(rhs.attoseconds)
        let rhsSumHigh = rhsHigh &+ (rhsCarry ? 1 : 0)

        // Perform 128-bit / 128-bit division
        // We want to compute: (lhsSumHigh * 2^64 + lhsSumLow) / (rhsSumHigh * 2^64 + rhsSumLow)
        // and return the result as a PrecisionTimeInterval

        // Simple case: both high parts are zero
        if lhsSumHigh == 0 && rhsSumHigh == 0 {
            let quotientSeconds = lhsSumLow / rhsSumLow
            let remainder = lhsSumLow % rhsSumLow

            // Convert remainder to attoseconds with full precision
            // remainder / rhsSumLow as attoseconds
            let (high, low) = remainder.multipliedFullWidth(by: Self.attosecondsPerSecond)
            let (quotientAttoseconds, _) = divide128By64(high: high, low: low, by: rhsSumLow)

            return PrecisionTimeInterval(
                SIMD2(quotientSeconds, quotientAttoseconds),
                lhs.sign == rhs.sign ? .positive : .negative
            )
        }

        // Complex case: use approximation for large numbers
        // Convert to Double for the division (loses precision but handles large ranges)
        let lhsDouble = Double(lhs.seconds) + Double(lhs.attoseconds) / Self.attosecondsPerSecondDouble
        let rhsDouble = Double(rhs.seconds) + Double(rhs.attoseconds) / Self.attosecondsPerSecondDouble
        let ratio = lhsDouble / rhsDouble

        return PrecisionTimeInterval(
            seconds: ratio
        ) * PrecisionTimeInterval(
            SIMD2(1, 0),
            lhs.sign == rhs.sign ? .positive : .negative
        )
    }
}
