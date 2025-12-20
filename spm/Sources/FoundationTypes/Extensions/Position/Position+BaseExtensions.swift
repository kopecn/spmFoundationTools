import Foundation

// MARK: - Equatable

/// Enables equality comparison for `Position` values.
///
/// Two positions are equal if all their vector components are equal.
/// - Parameters:
///   - lhs: The left-hand side position.
///   - rhs: The right-hand side position.
/// - Returns: `true` if all components are equal, otherwise `false`.
extension Position: Equatable {
    @inlinable
    public static func == (lhs: Position<T>, rhs: Position<T>) -> Bool {
        return lhs.vector == rhs.vector
    }
}

// MARK: - Hashable

/// Enables hashing for `Position` values when the underlying type is `Hashable`.
///
/// Hashes the x, y, and z components of the position.
extension Position: Hashable where T: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x)
        hasher.combine(vector.y)
        hasher.combine(vector.z)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible

/// Provides readable string representations for `Position` values.
///
/// - `description`: Returns a string in the form "Position(x: ..., y: ..., z: ...)".
/// - `debugDescription`: Returns a string in the form "Position<T>(x: ..., y: ..., z: ...)".
extension Position: CustomStringConvertible, CustomDebugStringConvertible {
    /// A human-readable description of the position.
    /// Example: `"Position(x: 1.0, y: 2.0, z: 3.0)"`
    public var description: String {
        return "Position(x: \(x), y: \(y), z: \(z))"
    }

    /// A debug description of the position, including the type.
    /// Example: `"Position<Double>(x: 1.0, y: 2.0, z: 3.0)"`
    public var debugDescription: String {
        return "Position<\(T.self)>(x: \(x), y: \(y), z: \(z))"
    }
}
