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
    public var storage: SIMD2<T>

    /// The real part of the complex number.
    @inlinable
    public var real: T {
        get { storage.x }
        set { storage.x = newValue }
    }

    /// The imaginary part of the complex number.
    @inlinable
    public var imaginary: T {
        get { storage.y }
        set { storage.y = newValue }
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
    @inlinable
    public init(real: T, imaginary: T) {
        self.storage = SIMD2(real, imaginary)
    }

    /// Initializes a complex number from a SIMD2 vector.
    /// - Parameter vector: A SIMD2 vector where `x` is the real part and `y` is the imaginary part.
    @inlinable
    public init(vector: SIMD2<T>) {
        self.storage = vector
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
        self.init(real: components[0], imaginary: components[1])
    }
}

/// Explicitly marks `Complex` as `Sendable` for concurrency safety.
extension Complex: @unchecked Sendable {}
