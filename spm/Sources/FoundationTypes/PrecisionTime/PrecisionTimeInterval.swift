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
    public static let attosecondsPerSecondDouble: Double = 1_000_000_000_000_000_000
    /// Number of attoseconds in one millisecond (1e15).
    public static let attosecondsPerMilliSecond: UInt64 = 1_000_000_000_000_000
    /// Number of attoseconds in one microsecond (1e12).
    public static let attosecondsPerMicroSecond: UInt64 = 1_000_000_000_000

    // MARK: - Normalization

    /// Single source of truth for normalization logic.
    /// Ensures attoseconds < attosecondsPerSecond and clamps seconds to UInt64.max on overflow.
    @inlinable
    internal static func normalize(_ storage: inout SIMD2<UInt64>, _ sign: inout NumericSign) {
        let totalSeconds = storage[0] &+ (storage[1] / attosecondsPerSecond)

        // Clamp to max if overflow
        guard totalSeconds >= storage[0] else {
            storage = SIMD2(UInt64.max, 0)
            return
        }

        storage = SIMD2(totalSeconds, storage[1] % attosecondsPerSecond)

        guard storage[0] == 0, storage[1] == 0 else { return }
        sign = .zero
    }

    // MARK: - Initializers

    /// Initialize directly from a SIMD2 vector
    @inlinable
    public init(
        _ storage: SIMD2<UInt64>,
        _ sign: NumericSign
    ) {
        self.storage = storage
        self.sign = sign
        Self.normalize(&self.storage, &self.sign)
    }

    @inlinable
    public init(
        seconds: UInt64 = 0,
        attoseconds: UInt64 = 0,
        sign: NumericSign
    ) {
        self.init(SIMD2(seconds, attoseconds), sign)
    }

    @inlinable
    public init(
        seconds: UInt64 = 0,
        milliseconds: UInt64 = 0,
        sign: NumericSign
    ) {
        // Check for overflow when adding extraSeconds to seconds
        switch seconds.addingReportingOverflow(milliseconds / 1000) {
        case (_, true):
            self.init(SIMD2(UInt64.max, 0), sign)
        case let (total, false):
            self.init(
                SIMD2(total, (milliseconds % 1000) * Self.attosecondsPerMilliSecond),
                sign
            )
        }
    }

    @inlinable
    public init<T:BinaryFloatingPoint>(
        seconds: T = 0
    ) {
        self.storage = SIMD2(0,0)
        self.sign = .zero
        Self.binaryFloatingPointToSimd(seconds, &self.storage, &self.sign)
    }

    @inlinable
    public init<T:BinaryInteger>(
        seconds: T = 0
    ) {
        self.storage = SIMD2(0,0)
        self.sign = .zero
        Self.binaryIntegerPointToSimd(seconds, &self.storage, &self.sign)
    }

    // MARK: - Accessors

    /// Seconds component
    @inlinable
    public var seconds: UInt64 {
        get { storage[0] }
        set {
            storage[0] = newValue
            Self.normalize(&self.storage, &self.sign)
        }
    }

    /// Attoseconds component
    @inlinable
    public var attoseconds: UInt64 {
        get { storage[1] }
        set {
            storage[1] = newValue
            Self.normalize(&self.storage, &self.sign)
        }
    }

    @inlinable
    public var secondsAsDouble: Double {
        get {
            return Double(storage[0]) + Double(storage[1] % Self.attosecondsPerSecond) / Self.attosecondsPerSecondDouble
                * (sign == .negative ? -1 : 1)
        }
        set {
            Self.binaryFloatingPointToSimd(newValue,&self.storage, &self.sign)
        }
    }

    /// Seconds component
    @inlinable
    public var secondsAsFloat: Float {
        get {
            return Float(storage[0]) + Float(
                //ensure this stays under Double before converting to float
                Double(storage[1] % Self.attosecondsPerSecond) / Self.attosecondsPerSecondDouble
            ) * (sign == .negative ? -1 : 1)
        }
        set {
            Self.binaryFloatingPointToSimd(newValue, &self.storage, &self.sign)
        }
    }

    @inlinable
    internal static func binaryFloatingPointToSimd<T: BinaryFloatingPoint>(
        _ value: T, 
        _ storage: inout SIMD2<UInt64>, 
        _ sign: inout NumericSign
    ) {

        guard value.isFinite else {
            storage = SIMD2(UInt64.max, 0)
            sign = NumericSign(value)
            return
        }

        let wholeSeconds = UInt64(abs(value))
        let fractionalAttoseconds = UInt64(
            (Double(value) - Double(wholeSeconds)) * Self.attosecondsPerSecondDouble
        )
        storage = SIMD2(wholeSeconds, fractionalAttoseconds)
        sign = NumericSign(value)
        Self.normalize(&storage, &sign)
    }
    @inlinable
    internal static func binaryIntegerPointToSimd<T: BinaryInteger>(
        _ value: T, 
        _ storage: inout SIMD2<UInt64>, 
        _ sign: inout NumericSign
    ) {
        storage = SIMD2(UInt64(value.magnitude), 0)
        sign = NumericSign(value)
        Self.normalize(&storage, &sign)
    }
}

extension PrecisionTimeInterval {
    public static var oneSecond: PrecisionTimeInterval {
        return PrecisionTimeInterval(seconds: 1, attoseconds: 0, sign: .positive)
    }
    public static var oneMillisecond: PrecisionTimeInterval {
        return PrecisionTimeInterval(seconds: 0, attoseconds: Self.attosecondsPerMilliSecond, sign: .positive)
    }
    public static var oneMicrosecond: PrecisionTimeInterval {
        return PrecisionTimeInterval(seconds: 0, attoseconds: Self.attosecondsPerMicroSecond, sign: .positive)
    }
}