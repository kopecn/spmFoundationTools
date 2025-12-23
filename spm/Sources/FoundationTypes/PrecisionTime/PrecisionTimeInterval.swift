import simd

/// Represents a time interval with attosecond precision
/// Stored as SIMD2<UInt64>: [seconds, attoseconds]
public struct PrecisionTimeInterval: Sendable {
    /// SIMD vector: [seconds, attoseconds]
    public var storage: SIMD2<UInt64>
    public var sign: NumericSign

    @inlinable
    public init(
        seconds: UInt64 = 0, 
        attoseconds: UInt64 = 0,
        sign: NumericSign
    ) {
        self.storage = SIMD2(seconds, attoseconds)
        self.sign = sign
    }

    /// Initialize directly from a SIMD2 vector
    @inlinable
    public init(
        storage: SIMD2<UInt64>,
        sign: NumericSign
    ) {
        self.storage = storage
        self.sign = sign
    }

    /// Seconds component
    
    @inlinable
    public var seconds: UInt64 {
        get { storage[0] }
        set { storage[0] = newValue }
    }

    /// Attoseconds component
    @inlinable
    public var attoseconds: UInt64 {
        get { storage[1] }
        set { storage[1] = newValue }
    }
}