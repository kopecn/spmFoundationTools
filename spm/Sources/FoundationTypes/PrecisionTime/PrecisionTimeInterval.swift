import simd

/// Represents a time interval with attosecond precision
/// Stored as SIMD2<UInt64>: [seconds, attoseconds]
public struct PrecisionTimeInterval: Sendable {
    /// SIMD vector: [seconds, attoseconds]
    public var storage: SIMD2<UInt64>
    public var sign: NumericSign

    // MARK: - Constants

    /// Number of attoseconds in one second (1e18).
    public static let attosecondsPerSecond: UInt64 = 1_000_000_000_000_000_000
    /// Number of attoseconds in one millisecond (1e15).
    public static let attosecondsPerMilliSecond: UInt64 = 1_000_000_000_000_000
    /// Number of attoseconds in one microsecond (1e12).
    public static let attosecondsPerMicroSecond: UInt64 = 1_000_000_000_000

    // MARK: - Normalization

    /// Single source of truth for normalization logic.
    /// Ensures attoseconds < attosecondsPerSecond and clamps seconds to UInt64.max on overflow.
    @inlinable
    internal static func normalize(seconds: UInt64, attoseconds: UInt64) -> SIMD2<UInt64> {
        let extraSeconds = attoseconds / attosecondsPerSecond
        let normalizedAttoseconds = attoseconds % attosecondsPerSecond
        let totalSeconds = seconds &+ extraSeconds

        // Clamp to max if overflow
        if totalSeconds < seconds || totalSeconds == UInt64.max {
            return SIMD2(UInt64.max, 0)
        } else {
            return SIMD2(totalSeconds, normalizedAttoseconds)
        }
    }

    // MARK: - Initializers

    /// Initialize directly from a SIMD2 vector
    @inlinable
    public init(
        storage: SIMD2<UInt64>,
        sign: NumericSign
    ) {
        self.storage = Self.normalize(seconds: storage[0], attoseconds: storage[1])
        self.sign = sign
    }

    @inlinable
    public init(
        seconds: UInt64 = 0,
        attoseconds: UInt64 = 0,
        sign: NumericSign
    ) {
        self.init(
            storage: SIMD2(seconds, attoseconds),
            sign: sign
        )
    }

    @inlinable
    public init(
        seconds: UInt64 = 0,
        milliseconds: UInt64 = 0,
        sign: NumericSign
    ) {
        let extraSeconds = milliseconds / 1000
        let millisecondsRemainder = milliseconds % 1000
        let attoseconds = millisecondsRemainder * Self.attosecondsPerMilliSecond

        // Check for overflow when adding extraSeconds to seconds
        let (totalSeconds, overflow) = seconds.addingReportingOverflow(extraSeconds)
        if overflow {
            // Clamp to maximum value
            self.storage = SIMD2(UInt64.max, 0)
        } else {
            // Let normalize handle attoseconds overflow
            self.storage = Self.normalize(seconds: totalSeconds, attoseconds: attoseconds)
        }
        self.sign = sign
    }

    // MARK: - Accessors

    /// Seconds component
    @inlinable
    public var seconds: UInt64 {
        get { storage[0] }
        set { storage = Self.normalize(seconds: newValue, attoseconds: storage[1]) }
    }

    /// Attoseconds component
    @inlinable
    public var attoseconds: UInt64 {
        get { storage[1] }
        set { storage = Self.normalize(seconds: storage[0], attoseconds: newValue) }
    }
}
