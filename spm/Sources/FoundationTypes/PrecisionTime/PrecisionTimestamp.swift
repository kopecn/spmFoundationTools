import simd
import Foundation


/// Represents a high-precision timestamp as (seconds since epoch, attoseconds within the second),
/// stored in a SIMD2<UInt64> vector for efficient operations.
///
/// This type provides attosecond precision (10^-18 seconds) and is designed to work
/// in both full Swift with Foundation (and planned Swift Embedded environments).
///
/// The timestamp is split into:
/// - Seconds since Unix epoch (1970-01-01 00:00:00 UTC)
/// - Attoseconds within the current second (0 to 999,999,999,999,999,999)
///
/// This representation allows for:
/// - SIMD-optimized operations
/// - No floating-point rounding errors
/// - High precision timing for scientific applications
/// - (Planned --> Compatibility with Swift Embedded no Foundation required)
public struct PrecisionTimestamp: Sendable {
    /// SIMD vector: [secondsSinceEpoch, attosecondsOfSecond]
    public var storage: SIMD2<UInt64>

    /// Time scale specification (e.g., TAI, TT, TCB).
    /// Recommended default: `.tai`, but defaults to `nil` if not specified.
    public var timescale: Timescale?

    /// Spatial reference frame (e.g., Earth center, solar system barycenter).
    /// Recommended default: `.earthCenter`, but defaults to `nil` if not specified.
    public var referenceFrame: ReferenceFrame?

    /// Uncertainty in the timestamp, measured in attoseconds (±).
    public var uncertainty: UInt64?

    // MARK: - Constants

    /// Number of attoseconds in one second (1e18).
    public static let attosecondsPerSecond: UInt64 = 1_000_000_000_000_000_000

    /// Number of seconds in one day.
    public static let secondsPerDay: UInt64 = 86_400

    // MARK: - Accessors

    /// Seconds since Unix epoch (1970-01-01 00:00:00 UTC).
    @inlinable
    public var seconds: UInt64 {
        get { storage[0] }
        set { storage[0] = newValue }
    }

    /// Attoseconds within the current second (0 to 999,999,999,999,999,999).
    @inlinable
    public var attoseconds: UInt64 {
        get { storage[1] }
        set {
            // Automatically wrap if exceeds one second
            let extraSeconds = newValue / Self.attosecondsPerSecond
            storage[1] = newValue % Self.attosecondsPerSecond
            storage[0] += extraSeconds
        }
    }

    /// Days since Unix epoch.
    @inlinable
    public var daysSinceEpoch: UInt64 {
        get { seconds / Self.secondsPerDay }
    }

    /// Seconds within the current day (0 to 86,399).
    @inlinable
    public var secondsOfDay: UInt64 {
        get { seconds % Self.secondsPerDay }
    }

    // MARK: - Initializers

    /// Initialize with seconds since epoch and attoseconds within that second, automatically wrapping if needed.
    @inlinable
    public init(
        seconds: UInt64,
        attoseconds: UInt64 = 0,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        let extraSeconds = attoseconds / Self.attosecondsPerSecond
        let wrappedAttoseconds = attoseconds % Self.attosecondsPerSecond
        self.storage = SIMD2(seconds + extraSeconds, wrappedAttoseconds)
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Initialize directly from a SIMD2 vector.
    @inlinable
    public init(
        storage: SIMD2<UInt64>,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        self.storage = storage
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Initialize with days since epoch and attoseconds within that day.
    @inlinable
    public init(
        daysSinceEpoch: UInt64,
        attosecondsOfDay: UInt64,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        let totalSeconds = daysSinceEpoch * Self.secondsPerDay
        let secondsInAttoseconds = attosecondsOfDay / Self.attosecondsPerSecond
        let remainingAttoseconds = attosecondsOfDay % Self.attosecondsPerSecond
        self.storage = SIMD2(totalSeconds + secondsInAttoseconds, remainingAttoseconds)
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Initialize to the current time.
    @inlinable
    public init(
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        self.init(
            date: Date(),
            timescale: timescale,
            referenceFrame: referenceFrame,
            uncertainty: uncertainty
        )
    }

    /// Initialize from a Foundation Date.
    @inlinable
    public init(
        date: Date,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        let timeInterval = date.timeIntervalSince1970
        let seconds = UInt64(timeInterval)
        let fractionalSeconds = timeInterval - Double(seconds)
        let attosecondsOfSecond = UInt64(fractionalSeconds * Double(Self.attosecondsPerSecond))

        self.storage = SIMD2(seconds, attosecondsOfSecond)
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Convert to a Foundation Date.
    /// Note: Date only has microsecond precision, so attosecond precision will be lost.
    @inlinable
    public var asFoundationDate: Date {
        let totalSeconds = Double(seconds)
        let fractionalSeconds = Double(attoseconds) / Double(Self.attosecondsPerSecond)
        return Date(timeIntervalSince1970: totalSeconds + fractionalSeconds)
    }
}
