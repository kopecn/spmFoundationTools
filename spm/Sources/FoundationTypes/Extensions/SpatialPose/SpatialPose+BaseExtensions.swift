import Foundation

// MARK: - Equatable

/// Enables equality comparison for `SpatialPose` values.
/// 
/// Two spatial poses are equal if both their position (`_pos`) and rotation (`_rot`) components are equal.
/// - Parameters:
///   - lhs: The left-hand side spatial pose.
///   - rhs: The right-hand side spatial pose.
/// - Returns: `true` if both position and rotation are equal, otherwise `false`.
extension SpatialPose: Equatable {
    public static func == (lhs: SpatialPose<T>, rhs: SpatialPose<T>) -> Bool {
        return lhs._pos == rhs._pos && lhs._rot == rhs._rot
    }
}

// MARK: - Hashable

/// Enables hashing for `SpatialPose` values when the underlying type is `Hashable`.
/// 
/// Hashes both the position and rotation components of the spatial pose.
extension SpatialPose: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_pos)
        hasher.combine(_rot)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible

/// Provides readable string representations for `SpatialPose` values.
/// 
/// - `description`: Returns a string in the form "SpatialPose(position: (x, y, z), rotation: (qx, qy, qz, qw))".
/// - `debugDescription`: Returns a string in the form "SpatialPose<T>(position: (x, y, z), rotation: (qx, qy, qz, qw))".
extension SpatialPose: CustomStringConvertible, CustomDebugStringConvertible {
    /// A human-readable description of the spatial pose.
    /// Example: `"SpatialPose(position: (1.0, 2.0, 3.0), rotation: (0.0, 0.0, 0.0, 1.0))"`
    public var description: String {
        return "SpatialPose(position: (\(x), \(y), \(z)), rotation: (\(qx), \(qy), \(qz), \(qw)))"
    }

    /// A debug description of the spatial pose, including the type.
    /// Example: `"SpatialPose<Double>(position: (1.0, 2.0, 3.0), rotation: (0.0, 0.0, 0.0, 1.0))"`
    public var debugDescription: String {
        return "SpatialPose<\(T.self)>(position: (\(x), \(y), \(z)), rotation: (\(qx), \(qy), \(qz), \(qw)))"
    }
}