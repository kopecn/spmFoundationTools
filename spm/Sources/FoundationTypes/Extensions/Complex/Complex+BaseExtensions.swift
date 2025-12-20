import Foundation

// MARK: - CustomStringConvertible, CustomDebugStringConvertible

/// Provides readable string representations for `Complex` numbers.
///
/// - `description`: Returns a string in the form "a + bi" or "a - bi".
/// - `debugDescription`: Returns a string in the form "Complex(real: a, imaginary: b)".
extension Complex: CustomStringConvertible, CustomDebugStringConvertible {
    /// A human-readable description of the complex number.
    /// Example: `"3.0 + 4.0i"` or `"3.0 - 4.0i"`
    public var description: String {
        if imaginary >= 0 {
            return "\(real) + \(imaginary)i"
        } else {
            return "\(real) - \(-imaginary)i"
        }
    }

    /// A debug description of the complex number.
    /// Example: `"Complex(real: 3.0, imaginary: 4.0)"`
    public var debugDescription: String {
        return "Complex(real: \(real), imaginary: \(imaginary))"
    }
}

// MARK: - Hashable

/// Enables hashing for `Complex` numbers when the underlying type is `Hashable`.
extension Complex: Hashable where T: Hashable {
    /// Hashes the essential components of the complex number.
    /// - Parameter hasher: The hasher to use when combining the components.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(real)
        hasher.combine(imaginary)
    }
}

// MARK: - Equatable

/// Enables equality comparison for `Complex` numbers.
extension Complex: Equatable {
    /// Returns `true` if both the real and imaginary parts are equal.
    /// - Parameters:
    ///   - lhs: The left-hand side complex number.
    ///   - rhs: The right-hand side complex number.
    @inlinable
    public static func == (lhs: Complex<T>, rhs: Complex<T>) -> Bool {
        return lhs.storage == rhs.storage
    }
}
