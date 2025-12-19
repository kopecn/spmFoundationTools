import Foundation
import simd

/// A typealias for a complex number with `Double` components.
public typealias ComplexDouble = Complex<Double>

/// A typealias for a complex number with `Float` components.
public typealias ComplexFloat = Complex<Float>

/// A generic struct representing a complex number with real and imaginary components.
/// - Note: `T` must conform to `BinaryFloatingPoint & SIMDScalar` (e.g., `Float`, `Double`).
public struct Complex<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable> {
    /// Internal SIMD2 storage for real and imaginary components.
    @usableFromInline
    internal var storage: SIMD2<T>

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

    /// Initializes a complex number with real and imaginary components.
    @inlinable
    public init(real: T, imaginary: T) {
        self.storage = SIMD2(real, imaginary)
    }

    /// Initializes a complex number from Vector.
    @inlinable
    public init(vector: SIMD2<T>) {
        self.storage = vector
    }
}


// Unsafe but explicit Sendable conformance
extension Complex: @unchecked Sendable {}


// MARK: - Collection Operations
extension Complex {

    /// Create a complex type from an array of components
    /// - Parameter components: Array containing [x, y] values
    /// - Returns: A new complex number, or nil if the array doesn't have exactly 2 elements
    public init?(components: [T]) {
        guard components.count == 2 else { return nil }
        self.init(real: components[0], imaginary: components[1])
    }

    /// Convert position to an array of components
    public var components: [T] {
        return [real, imaginary]
    }
}
