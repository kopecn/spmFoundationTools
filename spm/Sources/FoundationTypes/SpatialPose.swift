import Foundation
import simd

// Convenience typealiases for common use cases
public typealias FloatSpatialPose = SpatialPose<Float>
public typealias DoubleSpatialPose = SpatialPose<Double>

/// A spatial pose data structure combining 3D position and rotation.
///
/// `SpatialPose` represents a spatial transformation consisting of:
/// - `position`: A 3D position vector (x, y, z)
/// - `rotation`: A quaternion rotation (x, y, z, w)
///
/// Spatial poses provide an efficient way to represent the complete spatial state
/// of an object in 3D space, combining both translation and orientation.
///
/// Example usage:
/// ```swift
/// // Identity pose (origin with no rotation)
/// let identity = FloatSpatialPose.identity
///
/// // Pose from position and rotation vectors
/// let pose = DoubleSpatialPose(
///     position: SIMD3<Double>(1.0, 2.0, 3.0),
///     rotation: SIMD4<Double>(0, 0, 0, 1)
/// )
///
/// // Pose from individual components
/// let customPose = FloatSpatialPose(
///     x: 1.0, y: 2.0, z: 3.0,
///     qx: 0.0, qy: 0.0, qz: 0.0, qw: 1.0
/// )
/// ```
public struct SpatialPose<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable>: Codable {

    /// The position vector (x, y, z)
    public var _position: SIMD3<T>

    /// The rotation quaternion (x, y, z, w)
    public var _rotation: SIMD4<T>

    // MARK: - Position Components

    /// The x component of position
    @inlinable
    public var x: T {
        get { _position.x }
        set { _position.x = newValue }
    }

    /// The y component of position
    @inlinable
    public var y: T {
        get { _position.y }
        set { _position.y = newValue }
    }

    /// The z component of position
    @inlinable
    public var z: T {
        get { _position.z }
        set { _position.z = newValue }
    }

    // MARK: - Rotation Components

    /// The x component of rotation quaternion (i coefficient)
    @inlinable
    public var qx: T {
        get { _rotation.x }
        set { _rotation.x = newValue }
    }

    /// The y component of rotation quaternion (j coefficient)
    @inlinable
    public var qy: T {
        get { _rotation.y }
        set { _rotation.y = newValue }
    }

    /// The z component of rotation quaternion (k coefficient)
    @inlinable
    public var qz: T {
        get { _rotation.z }
        set { _rotation.z = newValue }
    }

    /// The w component of rotation quaternion (real part)
    @inlinable
    public var qw: T {
        get { _rotation.w }
        set { _rotation.w = newValue }
    }

    // MARK: - Type Conversions

    /// Get the position as a Position type
    @inlinable
    public var position: Position<T> {
        return Position<T>(vector: _position)
    }

    /// Get the rotation as a Quaternion type
    @inlinable
    public var quaternion: Quaternion<T> {
        return Quaternion<T>(vector: _rotation)
    }

    // MARK: - Initializers

    /// Initialize a pose with position and rotation vectors
    /// - Parameters:
    ///   - position: The position vector (x, y, z)
    ///   - rotation: The rotation quaternion (x, y, z, w)
    public init(position: SIMD3<T>, rotation: SIMD4<T>) {
        self._position = position
        self._rotation = rotation
    }

    /// Initialize a pose with individual components
    /// - Parameters:
    ///   - x: The x component of position
    ///   - y: The y component of position
    ///   - z: The z component of position
    ///   - qx: The x component of rotation quaternion
    ///   - qy: The y component of rotation quaternion
    ///   - qz: The z component of rotation quaternion
    ///   - qw: The w component of rotation quaternion
    public init(x: T, y: T, z: T, qx: T, qy: T, qz: T, qw: T) {
        self._position = SIMD3<T>(x, y, z)
        self._rotation = SIMD4<T>(qx, qy, qz, qw)
    }

    /// Initialize a pose from Position and Quaternion types
    /// - Parameters:
    ///   - position: The Position instance
    ///   - rotation: The Quaternion instance
    public init(position: Position<T>, rotation: Quaternion<T>) {
        self._position = position.vector
        self._rotation = rotation.vector
    }

    /// Initialize a pose from a 4x4 homogeneous transformation matrix
    /// - Parameter matrix: The 4x4 transformation matrix
    /// - Note: The matrix should be in column-major order with rotation in the upper-left 3x3
    ///         and translation in the last column
    public init(homogeneousTransform: simd_float4x4) where T == Float {
        // Extract translation from last column
        self._position = SIMD3<T>(
            homogeneousTransform.columns.3.x,
            homogeneousTransform.columns.3.y,
            homogeneousTransform.columns.3.z
        )

        // Extract rotation matrix (upper-left 3x3)
        let m00 = homogeneousTransform.columns.0.x
        let m01 = homogeneousTransform.columns.1.x
        let m02 = homogeneousTransform.columns.2.x
        let m10 = homogeneousTransform.columns.0.y
        let m11 = homogeneousTransform.columns.1.y
        let m12 = homogeneousTransform.columns.2.y
        let m20 = homogeneousTransform.columns.0.z
        let m21 = homogeneousTransform.columns.1.z
        let m22 = homogeneousTransform.columns.2.z

        // Convert rotation matrix to quaternion
        let trace = m00 + m11 + m22

        if trace > 0 {
            let s = sqrt(trace + 1.0) * 2
            let qw = 0.25 * s
            let qx = (m21 - m12) / s
            let qy = (m02 - m20) / s
            let qz = (m10 - m01) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m00 > m11 && m00 > m22 {
            let s = sqrt(1.0 + m00 - m11 - m22) * 2
            let qw = (m21 - m12) / s
            let qx = 0.25 * s
            let qy = (m01 + m10) / s
            let qz = (m02 + m20) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m11 > m22 {
            let s = sqrt(1.0 + m11 - m00 - m22) * 2
            let qw = (m02 - m20) / s
            let qx = (m01 + m10) / s
            let qy = 0.25 * s
            let qz = (m12 + m21) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else {
            let s = sqrt(1.0 + m22 - m00 - m11) * 2
            let qw = (m10 - m01) / s
            let qx = (m02 + m20) / s
            let qy = (m12 + m21) / s
            let qz = 0.25 * s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        }
    }

    /// Initialize a pose from a 4x4 homogeneous transformation matrix
    /// - Parameter matrix: The 4x4 transformation matrix
    /// - Note: The matrix should be in column-major order with rotation in the upper-left 3x3
    ///         and translation in the last column
    public init(homogeneousTransform: simd_double4x4) where T == Double {
        // Extract translation from last column
        self._position = SIMD3<T>(
            homogeneousTransform.columns.3.x,
            homogeneousTransform.columns.3.y,
            homogeneousTransform.columns.3.z
        )

        // Extract rotation matrix (upper-left 3x3)
        let m00 = homogeneousTransform.columns.0.x
        let m01 = homogeneousTransform.columns.1.x
        let m02 = homogeneousTransform.columns.2.x
        let m10 = homogeneousTransform.columns.0.y
        let m11 = homogeneousTransform.columns.1.y
        let m12 = homogeneousTransform.columns.2.y
        let m20 = homogeneousTransform.columns.0.z
        let m21 = homogeneousTransform.columns.1.z
        let m22 = homogeneousTransform.columns.2.z

        // Convert rotation matrix to quaternion
        let trace = m00 + m11 + m22

        if trace > 0 {
            let s = sqrt(trace + 1.0) * 2
            let qw = 0.25 * s
            let qx = (m21 - m12) / s
            let qy = (m02 - m20) / s
            let qz = (m10 - m01) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m00 > m11 && m00 > m22 {
            let s = sqrt(1.0 + m00 - m11 - m22) * 2
            let qw = (m21 - m12) / s
            let qx = 0.25 * s
            let qy = (m01 + m10) / s
            let qz = (m02 + m20) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m11 > m22 {
            let s = sqrt(1.0 + m11 - m00 - m22) * 2
            let qw = (m02 - m20) / s
            let qx = (m01 + m10) / s
            let qy = 0.25 * s
            let qz = (m12 + m21) / s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        } else {
            let s = sqrt(1.0 + m22 - m00 - m11) * 2
            let qw = (m10 - m01) / s
            let qx = (m02 + m20) / s
            let qy = (m12 + m21) / s
            let qz = 0.25 * s
            self._rotation = SIMD4<T>(qx, qy, qz, qw)
        }
    }

    // MARK: - Static Properties

    /// The identity pose (origin position with no rotation)
    @inlinable
    public static var identity: SpatialPose<T> {
        return SpatialPose<T>(
            position: SIMD3<T>(0, 0, 0),
            rotation: SIMD4<T>(0, 0, 0, 1)
        )
    }

    /// A zero pose (all components are zero)
    @inlinable
    public static var zero: SpatialPose<T> {
        return SpatialPose<T>(
            position: SIMD3<T>(0, 0, 0),
            rotation: SIMD4<T>(0, 0, 0, 0)
        )
    }
}

// MARK: - Matrix Conversion
extension SpatialPose where T == Float {
    /// Convert the pose to a 4x4 homogeneous transformation matrix
    /// - Returns: A 4x4 transformation matrix in column-major order
    public var homogeneousTransform: simd_float4x4 {
        let q = _rotation

        // Normalize quaternion
        let length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
        let qx = q.x / length
        let qy = q.y / length
        let qz = q.z / length
        let qw = q.w / length

        // Convert quaternion to rotation matrix
        let xx = qx * qx
        let yy = qy * qy
        let zz = qz * qz
        let xy = qx * qy
        let xz = qx * qz
        let yz = qy * qz
        let wx = qw * qx
        let wy = qw * qy
        let wz = qw * qz

        let col0 = SIMD4<Float>(1 - 2 * (yy + zz), 2 * (xy + wz), 2 * (xz - wy), 0)
        let col1 = SIMD4<Float>(2 * (xy - wz), 1 - 2 * (xx + zz), 2 * (yz + wx), 0)
        let col2 = SIMD4<Float>(2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (xx + yy), 0)
        let col3 = SIMD4<Float>(_position.x, _position.y, _position.z, 1)

        return simd_float4x4(col0, col1, col2, col3)
    }
}

extension SpatialPose where T == Double {
    /// Convert the pose to a 4x4 homogeneous transformation matrix
    /// - Returns: A 4x4 transformation matrix in column-major order
    public var homogeneousTransform: simd_double4x4 {
        let q = _rotation

        // Normalize quaternion
        let length = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
        let qx = q.x / length
        let qy = q.y / length
        let qz = q.z / length
        let qw = q.w / length

        // Convert quaternion to rotation matrix
        let xx = qx * qx
        let yy = qy * qy
        let zz = qz * qz
        let xy = qx * qy
        let xz = qx * qz
        let yz = qy * qz
        let wx = qw * qx
        let wy = qw * qy
        let wz = qw * qz

        let col0 = SIMD4<Double>(1 - 2 * (yy + zz), 2 * (xy + wz), 2 * (xz - wy), 0)
        let col1 = SIMD4<Double>(2 * (xy - wz), 1 - 2 * (xx + zz), 2 * (yz + wx), 0)
        let col2 = SIMD4<Double>(2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (xx + yy), 0)
        let col3 = SIMD4<Double>(_position.x, _position.y, _position.z, 1)

        return simd_double4x4(col0, col1, col2, col3)
    }
}

// MARK: - Equatable
extension SpatialPose: Equatable {
    public static func == (lhs: SpatialPose<T>, rhs: SpatialPose<T>) -> Bool {
        return lhs._position == rhs._position && lhs._rotation == rhs._rotation
    }
}

// MARK: - Hashable
extension SpatialPose: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_position.x)
        hasher.combine(_position.y)
        hasher.combine(_position.z)
        hasher.combine(_rotation.x)
        hasher.combine(_rotation.y)
        hasher.combine(_rotation.z)
        hasher.combine(_rotation.w)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension SpatialPose: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "SpatialPose(position: (\(x), \(y), \(z)), rotation: (\(qx), \(qy), \(qz), \(qw)))"
    }

    public var debugDescription: String {
        return "SpatialPose<\(T.self)>(position: (\(x), \(y), \(z)), rotation: (\(qx), \(qy), \(qz), \(qw)))"
    }
}

// MARK: - Codable Implementation
extension SpatialPose {
    private enum CodingKeys: String, CodingKey {
        case x, y, z
        case qx, qy, qz, qw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let z = try container.decode(T.self, forKey: .z)
        let qx = try container.decode(T.self, forKey: .qx)
        let qy = try container.decode(T.self, forKey: .qy)
        let qz = try container.decode(T.self, forKey: .qz)
        let qw = try container.decode(T.self, forKey: .qw)

        self.init(x: x, y: y, z: z, qx: qx, qy: qy, qz: qz, qw: qw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
        try container.encode(qx, forKey: .qx)
        try container.encode(qy, forKey: .qy)
        try container.encode(qz, forKey: .qz)
        try container.encode(qw, forKey: .qw)
    }
}

// Unsafe but explicit Sendable conformance
extension SpatialPose: @unchecked Sendable {}
