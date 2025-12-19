import Foundation
import simd

/// A typealias for a complex number with `Double` components.
public typealias ComplexDouble = Complex<Double>

/// A typealias for a complex number with `Float` components.
public typealias ComplexFloat = Complex<Float>

/// A generic struct representing a complex number with real and imaginary components.
/// - Note: `T` must conform to `BinaryFloatingPoint & SIMDScalar` (e.g., `Float`, `Double`).
public struct Complex<T: BinaryFloatingPoint & SIMDScalar & Sendable> {
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


// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Complex: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        if imaginary >= 0 {
            return "\(real) + \(imaginary)i"
        } else {
            return "\(real) - \(-imaginary)i"
        }
    }

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        return "Complex(real: \(real), imaginary: \(imaginary))"
    }
}

// MARK: - Hashable
extension Complex: Hashable where T: Hashable{
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(real)
        hasher.combine(imaginary)
    }
}

// MARK: - Equatable
extension Complex: Equatable {
    @inlinable
    public static func == (lhs: Complex<T>, rhs: Complex<T>) -> Bool {
        return lhs.storage == rhs.storage
    }
}