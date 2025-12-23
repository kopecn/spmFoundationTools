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
public struct PrecisionTimestamp {
    /// SIMD vector: [secondsSinceEpoch, attosecondsOfSecond]
    public var storage: SIMD2<UInt64>

    // MARK: - Constants

    /// Number of attoseconds in one second (1e18).
    public static let attosecondsPerSecond: UInt64 = 1_000_000_000_000_000_000

    /// Number of seconds in one day.
    public static let secondsPerDay: UInt64 = 86_400

    // MARK: - Accessors

    /// Seconds since Unix epoch (1970-01-01 00:00:00 UTC).
    @inlinable
    public var secondsSinceEpoch: UInt64 {
        get { storage[0] }
        set { storage[0] = newValue }
    }

    /// Attoseconds within the current second (0 to 999,999,999,999,999,999).
    @inlinable
    public var attosecondsOfSecond: UInt64 {
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
        get { secondsSinceEpoch / Self.secondsPerDay }
    }

    /// Seconds within the current day (0 to 86,399).
    @inlinable
    public var secondsOfDay: UInt64 {
        get { secondsSinceEpoch % Self.secondsPerDay }
    }

    // MARK: - Initializers

    /// Initialize with seconds since epoch and attoseconds within that second, automatically wrapping if needed.
    @inlinable
    public init(secondsSinceEpoch: UInt64, attosecondsOfSecond: UInt64 = 0) {
        let extraSeconds = attosecondsOfSecond / Self.attosecondsPerSecond
        let wrappedAttoseconds = attosecondsOfSecond % Self.attosecondsPerSecond
        self.storage = SIMD2(secondsSinceEpoch + extraSeconds, wrappedAttoseconds)
    }

    /// Initialize directly from a SIMD2 vector.
    @inlinable
    public init(storage: SIMD2<UInt64>) {
        self.init(secondsSinceEpoch: storage[0], attosecondsOfSecond: storage[1])
    }

    /// Initialize with days since epoch and attoseconds within that day.
    @inlinable
    public init(daysSinceEpoch: UInt64, attosecondsOfDay: UInt64) {
        let totalSeconds = daysSinceEpoch * Self.secondsPerDay
        let secondsInAttoseconds = attosecondsOfDay / Self.attosecondsPerSecond
        let remainingAttoseconds = attosecondsOfDay % Self.attosecondsPerSecond
        self.init(secondsSinceEpoch: totalSeconds + secondsInAttoseconds, attosecondsOfSecond: remainingAttoseconds)
    }

    /// Initialize to the current time.
    @inlinable
    public init() {
        self.init(date: Date())
    }

    /// Initialize from a Foundation Date.
    @inlinable
    public init(date: Date) {
        let timeInterval = date.timeIntervalSince1970
        let seconds = UInt64(timeInterval)
        let fractionalSeconds = timeInterval - Double(seconds)
        let attosecondsOfSecond = UInt64(fractionalSeconds * Double(Self.attosecondsPerSecond))
        self.init(secondsSinceEpoch: seconds, attosecondsOfSecond: attosecondsOfSecond)
    }

    /// Convert to a Foundation Date.
    /// Note: Date only has microsecond precision, so attosecond precision will be lost.
    @inlinable
    public var asFoundationDate: Date {
        let totalSeconds = Double(secondsSinceEpoch)
        let fractionalSeconds = Double(attosecondsOfSecond) / Double(Self.attosecondsPerSecond)
        return Date(timeIntervalSince1970: totalSeconds + fractionalSeconds)
    }
}
