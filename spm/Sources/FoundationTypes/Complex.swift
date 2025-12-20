import Foundation
import simd

/// A typealias for a complex number with `Double` components.
/// Use `ComplexDouble` for most scientific and engineering applications.
public typealias ComplexDouble = Complex<Double>

/// A typealias for a complex number with `Float` components.
/// Use `ComplexFloat` for performance-sensitive applications.
public typealias ComplexFloat = Complex<Float>

/// A generic struct representing a complex number with real and imaginary components.
/// - Note: `T` must conform to `BinaryFloatingPoint & SIMDScalar` (e.g., `Float`, `Double`).
///
/// Example usage:
/// ```swift
/// let z = Complex<Double>(real: 1.0, imaginary: 2.0)
/// print(z.real)      // 1.0
/// print(z.imaginary) // 2.0
/// ```
public struct Complex<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable> {
    /// Internal SIMD2 storage for real and imaginary components.
    public var storage: SIMD2<T> {
        didSet {
            _isNormalized = false
        }
    }

    /// Cached flag indicating whether this complex number is normalized
    @usableFromInline
    internal var _isNormalized: Bool

    /// The real part of the complex number.
    @inlinable
    public var real: T {
        get { storage.x }
        set {
            storage.x = newValue
            _isNormalized = false
        }
    }

    /// The imaginary part of the complex number.
    @inlinable
    public var imaginary: T {
        get { storage.y }
        set {
            storage.y = newValue
            _isNormalized = false
        }
    }

    /// Converts the complex number to an array of components `[real, imaginary]`.
    @inlinable
    public var components: [T] {
        return [real, imaginary]
    }

    /// Initializes a complex number with real and imaginary components.
    /// - Parameters:
    ///   - real: The real part.
    ///   - imaginary: The imaginary part.
    ///   - isNormalized: Whether this complex number is known to be normalized (default: false)
    @inlinable
    public init(real: T, imaginary: T, isNormalized: Bool = false) {
        self.storage = SIMD2(real, imaginary)
        self._isNormalized = isNormalized
    }

    /// Initializes a complex number from a SIMD2 vector.
    /// - Parameters:
    ///   - vector: A SIMD2 vector where `x` is the real part and `y` is the imaginary part.
    ///   - isNormalized: Whether this complex number is known to be normalized (default: false)
    @inlinable
    public init(vector: SIMD2<T>, isNormalized: Bool = false) {
        self.storage = vector
        self._isNormalized = isNormalized
    }

    /// Creates a complex number from an array of components.
    /// - Parameter components: Array containing `[real, imaginary]` values.
    /// - Returns: A new complex number, or `nil` if the array doesn't have exactly 2 elements.
    ///
    /// Example:
    /// ```swift
    /// let z = Complex<Double>(components: [1.0, 2.0])
    /// ```
    public init?(components: [T]) {
        guard components.count == 2 else { return nil }
        self.storage = SIMD2(components[0], components[1])
        self._isNormalized = false
    }
}

/// Explicitly marks `Complex` as `Sendable` for concurrency safety.
extension Complex: @unchecked Sendable {}

// MARK: - Phasor/Polar Initializer (Double)

extension Complex where T == Double {
    /// Initializes a complex number from polar/phasor form.
    /// - Parameters:
    ///   - magnitude: The magnitude (radius) of the complex number.
    ///   - phase: The phase angle in radians.
    ///
    /// Creates a complex number where:
    /// - `real = magnitude * cos(phase)`
    /// - `imaginary = magnitude * sin(phase)`
    ///
    /// Example:
    /// ```swift
    /// let z = Complex<Double>(magnitude: 1.0, phase: .pi / 4)
    /// // Creates complex number at 45 degrees: ≈ 0.707 + 0.707i
    /// ```
    @inlinable
    public init(magnitude: T, phase: T) {
        var sinValue: T = 0
        var cosValue: T = 0
        __sincos(phase, &sinValue, &cosValue)
        self.storage = SIMD2(magnitude * cosValue, magnitude * sinValue)
        self._isNormalized = abs(magnitude - 1) < 1e-10
    }
}

// MARK: - Phasor/Polar Initializer (Float)

extension Complex where T == Float {
    /// Initializes a complex number from polar/phasor form.
    /// - Parameters:
    ///   - magnitude: The magnitude (radius) of the complex number.
    ///   - phase: The phase angle in radians.
    ///
    /// Creates a complex number where:
    /// - `real = magnitude * cos(phase)`
    /// - `imaginary = magnitude * sin(phase)`
    ///
    /// Example:
    /// ```swift
    /// let z = Complex<Float>(magnitude: 1.0, phase: .pi / 4)
    /// // Creates complex number at 45 degrees: ≈ 0.707 + 0.707i
    /// ```
    @inlinable
    public init(magnitude: T, phase: T) {
        var sinValue: T = 0
        var cosValue: T = 0
        __sincosf(phase, &sinValue, &cosValue)
        self.storage = SIMD2(magnitude * cosValue, magnitude * sinValue)
        self._isNormalized = abs(magnitude - 1) < 1e-5
    }
}

extension Complex {

    /// Returns the cached normalization flag.
    ///
    /// This flag is automatically maintained by the Complex type:
    /// - Set to `true` after callsing `normalize()` or when created via normalizing initializers
    /// - Set to `false` when any component is modified (real, imaginary, storage)
    /// - Defaults to `false` for basic initializers unless explicitly specified
    ///
    /// For actual runtime verification of normalization, use `isUnit` instead,
    /// which computes the magnitude and checks if it's approximately 1.
    @inlinable
    public var isNormalized: Bool {
        _isNormalized
    }
}
