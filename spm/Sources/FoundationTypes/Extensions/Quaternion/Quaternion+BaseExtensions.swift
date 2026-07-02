import Foundation

// MARK: - Equatable

/// Enables equality comparison for `Quaternion` values.
///
/// Two quaternions are equal if all their vector components are equal.
/// - Parameters:
///   - lhs: The left-hand side quaternion.
///   - rhs: The right-hand side quaternion.
/// - Returns: `true` if all components are equal, otherwise `false`.
extension Quaternion: Equatable {
    @inlinable
    public static func == (lhs: Quaternion<T>, rhs: Quaternion<T>) -> Bool {
        lhs.vector == rhs.vector
    }
}

// MARK: - Hashable

/// Enables hashing for `Quaternion` values when the underlying type is `Hashable`.
///
/// Hashes the x, y, z, and w components of the quaternion.
extension Quaternion: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x)
        hasher.combine(vector.y)
        hasher.combine(vector.z)
        hasher.combine(vector.w)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible

/// Provides readable string representations for `Quaternion` values.
///
/// - `description`: Returns a string in the form "Quaternion(x: ..., y: ..., z: ..., w: ...)".
/// - `debugDescription`: Returns a string in the form "Quaternion<T>(x: ..., y: ..., z: ..., w: ...)".
extension Quaternion: CustomStringConvertible, CustomDebugStringConvertible {
    /// A human-readable description of the quaternion.
    /// Example: `"Quaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)"`
    public var description: String {
        return "Quaternion(x: \(x), y: \(y), z: \(z), w: \(w))"
    }

    /// A debug description of the quaternion, including the type.
    /// Example: `"Quaternion<Double>(x: 1.0, y: 2.0, z: 3.0, w: 4.0)"`
    public var debugDescription: String {
        return "Quaternion<\(T.self)>(x: \(x), y: \(y), z: \(z), w: \(w))"
    }
}
