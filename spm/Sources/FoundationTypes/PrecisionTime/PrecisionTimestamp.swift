import Foundation
import simd

/// Represents a high-precision timestamp as a time interval from Unix epoch.
///
/// This type provides attosecond precision (10^-18 seconds) and is designed to work
/// in both full Swift with Foundation (and planned Swift Embedded environments).
///
/// The timestamp is represented as a `PrecisionTimeInterval` from Unix epoch (1970-01-01 00:00:00 UTC):
/// - Positive intervals represent times after epoch
/// - Negative intervals represent times before epoch (pre-1970)
/// - Zero represents exactly the Unix epoch
///
/// This representation allows for:
/// - Full arithmetic operations inherited from PrecisionTimeInterval
/// - No floating-point rounding errors
/// - High precision timing for scientific applications
/// - Support for dates before 1970 (including historical and astronomical dates)
/// - Automatic normalization and overflow protection
/// - (Planned --> Compatibility with Swift Embedded no Foundation required)
public struct PrecisionTimestamp: Sendable {
    /// Time interval since Unix epoch (can be negative for pre-1970 dates)
    public var interval: PrecisionTimeInterval

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
    public static let attosecondsPerSecond: UInt64 = PrecisionTimeInterval.attosecondsPerSecond

    /// Number of seconds in one day.
    public static let secondsPerDay: UInt64 = 86_400

    // MARK: - Accessors

    /// Seconds since Unix epoch (can be negative for pre-1970 dates).
    /// The magnitude is stored in interval.seconds, sign in interval.sign.
    @inlinable
    public var seconds: UInt64 {
        get { interval.seconds }
        set { interval.seconds = newValue }
    }

    /// Attoseconds within the current second (0 to 999,999,999,999,999,999).
    /// Always normalized to be less than attosecondsPerSecond.
    @inlinable
    public var attoseconds: UInt64 {
        get { interval.attoseconds }
        set { interval.attoseconds = newValue }
    }

    /// Sign of the timestamp relative to epoch (.positive for after, .negative for before)
    @inlinable
    public var sign: NumericSign {
        get { interval.sign }
        set { interval.sign = newValue }
    }

    /// Days since Unix epoch (magnitude only, check sign separately).
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

    /// Initialize with seconds since epoch and attoseconds within that second.
    /// Automatically normalizes attoseconds and handles overflow.
    @inlinable
    public init(
        seconds: UInt64,
        attoseconds: UInt64 = 0,
        sign: NumericSign = .positive,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        self.interval = PrecisionTimeInterval(
            seconds: seconds,
            attoseconds: attoseconds,
            sign: sign
        )
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Initialize directly from a PrecisionTimeInterval.
    @inlinable
    public init(
        interval: PrecisionTimeInterval,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        self.interval = interval
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    /// Initialize with days since epoch and attoseconds within that day.
    @inlinable
    public init(
        daysSinceEpoch: UInt64,
        attosecondsOfDay: UInt64,
        sign: NumericSign = .positive,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        let totalSeconds = daysSinceEpoch * Self.secondsPerDay
        let secondsInAttoseconds = attosecondsOfDay / Self.attosecondsPerSecond
        let remainingAttoseconds = attosecondsOfDay % Self.attosecondsPerSecond

        self.interval = PrecisionTimeInterval(
            seconds: totalSeconds + secondsInAttoseconds,
            attoseconds: remainingAttoseconds,
            sign: sign
        )
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
    /// Properly handles dates before 1970 (negative time intervals).
    @inlinable
    public init(
        date: Date,
        timescale: Timescale? = nil,
        referenceFrame: ReferenceFrame? = nil,
        uncertainty: UInt64? = nil
    ) {
        let timeInterval = date.timeIntervalSince1970

        // Determine sign and magnitude
        let sign: NumericSign = timeInterval >= 0 ? .positive : .negative
        let absTimeInterval = abs(timeInterval)

        // Split into seconds and fractional part
        let seconds = UInt64(absTimeInterval)
        let fractionalSeconds = absTimeInterval - Double(seconds)
        let attosecondsOfSecond = UInt64(fractionalSeconds * Double(Self.attosecondsPerSecond))

        self.interval = PrecisionTimeInterval(
            seconds: seconds,
            attoseconds: attosecondsOfSecond,
            sign: sign
        )
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
        let timeInterval = totalSeconds + fractionalSeconds

        // Apply sign
        let signedInterval = sign == .positive ? timeInterval : -timeInterval

        return Date(timeIntervalSince1970: signedInterval)
    }
}
