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
    public var _pos: Position<T>

    /// The rotation quaternion (x, y, z, w)
    public var _rot: Quaternion<T>

    // MARK: - Position Components

    /// The x component of position
    @inlinable
    public var x: T {
        get { _pos.x }
        set { _pos.x = newValue }
    }

    /// The y component of position
    @inlinable
    public var y: T {
        get { _pos.y }
        set { _pos.y = newValue }
    }

    /// The z component of position
    @inlinable
    public var z: T {
        get { _pos.z }
        set { _pos.z = newValue }
    }

    // MARK: - Rotation Components

    /// The x component of rotation quaternion (i coefficient)
    @inlinable
    public var qx: T {
        get { _rot.x }
        set { _rot.x = newValue }
    }

    /// The y component of rotation quaternion (j coefficient)
    @inlinable
    public var qy: T {
        get { _rot.y }
        set { _rot.y = newValue }
    }

    /// The z component of rotation quaternion (k coefficient)
    @inlinable
    public var qz: T {
        get { _rot.z }
        set { _rot.z = newValue }
    }

    /// The w component of rotation quaternion (real part)
    @inlinable
    public var qw: T {
        get { _rot.w }
        set { _rot.w = newValue }
    }

    // MARK: - Type Conversions

    /// Get the position as a Position type
    @inlinable
    public var position: Position<T> {
        return _pos
    }

    /// Get the rotation as a Quaternion type
    @inlinable
    public var quaternion: Quaternion<T> {
        return _rot
    }


    // MARK: - Initializers

    /// Initialize a pose with position and rotation vectors
    /// - Parameters:
    ///   - position: The position vector (x, y, z)
    ///   - rotation: The rotation quaternion (x, y, z, w)
    ///   - isNormalized: Whether the rotation quaternion is known to be normalized (default: false)
    public init(position: SIMD3<T>, rotation: SIMD4<T>, isNormalized: Bool = false) {
        self._pos = Position<T>(vector: position)
        self._rot = Quaternion<T>(vector: rotation, isNormalized: isNormalized)
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
    ///   - isNormalized: Whether the rotation quaternion is known to be normalized (default: false)
    public init(x: T, y: T, z: T, qx: T, qy: T, qz: T, qw: T, isNormalized: Bool = false) {
        self._pos = Position<T>(x: x, y: y, z: z)
        self._rot = Quaternion<T>(x: qx, y: qy, z: qz, w: qw, isNormalized: isNormalized)
    }

    /// Initialize a pose from Position and Quaternion types
    /// - Parameters:
    ///   - position: The Position instance
    ///   - rotation: The Quaternion instance
    public init(position: Position<T>, rotation: Quaternion<T>) {
        self._pos = position
        self._rot = rotation
    }

    /// Initialize a pose from a 4x4 homogeneous transformation matrix
    /// - Parameter matrix: The 4x4 transformation matrix
    /// - Note: The matrix should be in column-major order with rotation in the upper-left 3x3
    ///         and translation in the last column
    public init(homogeneousTransform: simd_float4x4, normalize: Bool = false) where T == Float {
        // Extract translation from last column
        let position = SIMD3<T>(
            homogeneousTransform.columns.3.x,
            homogeneousTransform.columns.3.y,
            homogeneousTransform.columns.3.z
        )
        self._pos = Position<T>(vector: position)

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

        let rotation: SIMD4<T>
        if trace > 0 {
            let s = sqrt(trace + 1.0) * 2
            let qw = 0.25 * s
            let qx = (m21 - m12) / s
            let qy = (m02 - m20) / s
            let qz = (m10 - m01) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m00 > m11 && m00 > m22 {
            let s = sqrt(1.0 + m00 - m11 - m22) * 2
            let qw = (m21 - m12) / s
            let qx = 0.25 * s
            let qy = (m01 + m10) / s
            let qz = (m02 + m20) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m11 > m22 {
            let s = sqrt(1.0 + m11 - m00 - m22) * 2
            let qw = (m02 - m20) / s
            let qx = (m01 + m10) / s
            let qy = 0.25 * s
            let qz = (m12 + m21) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else {
            let s = sqrt(1.0 + m22 - m00 - m11) * 2
            let qw = (m10 - m01) / s
            let qx = (m02 + m20) / s
            let qy = (m12 + m21) / s
            let qz = 0.25 * s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        }
        // Quaternions extracted from matrices are not guaranteed to be normalized
        self._rot = Quaternion<T>(vector: rotation, isNormalized: false)
        if normalize {
            self._rot.normalize()
        }
    }

    /// Initialize a pose from a 4x4 homogeneous transformation matrix
    /// - Parameter matrix: The 4x4 transformation matrix
    /// - Note: The matrix should be in column-major order with rotation in the upper-left 3x3
    ///         and translation in the last column
    public init(homogeneousTransform: simd_double4x4, normalize: Bool = false) where T == Double {
        // Extract translation from last column
        let position = SIMD3<T>(
            homogeneousTransform.columns.3.x,
            homogeneousTransform.columns.3.y,
            homogeneousTransform.columns.3.z
        )
        self._pos = Position<T>(vector: position)

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

        let rotation: SIMD4<T>
        if trace > 0 {
            let s = sqrt(trace + 1.0) * 2
            let qw = 0.25 * s
            let qx = (m21 - m12) / s
            let qy = (m02 - m20) / s
            let qz = (m10 - m01) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m00 > m11 && m00 > m22 {
            let s = sqrt(1.0 + m00 - m11 - m22) * 2
            let qw = (m21 - m12) / s
            let qx = 0.25 * s
            let qy = (m01 + m10) / s
            let qz = (m02 + m20) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else if m11 > m22 {
            let s = sqrt(1.0 + m11 - m00 - m22) * 2
            let qw = (m02 - m20) / s
            let qx = (m01 + m10) / s
            let qy = 0.25 * s
            let qz = (m12 + m21) / s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        } else {
            let s = sqrt(1.0 + m22 - m00 - m11) * 2
            let qw = (m10 - m01) / s
            let qx = (m02 + m20) / s
            let qy = (m12 + m21) / s
            let qz = 0.25 * s
            rotation = SIMD4<T>(qx, qy, qz, qw)
        }
        // Quaternions extracted from matrices are not guaranteed to be normalized
        self._rot = Quaternion<T>(vector: rotation, isNormalized: false)
        if normalize {
            self._rot.normalize()
        }
    }

    // MARK: - Static Properties

    /// The identity pose (origin position with no rotation)
    @inlinable
    public static var identity: SpatialPose<T> {
        return SpatialPose<T>(
            position: SIMD3<T>(0, 0, 0),
            rotation: SIMD4<T>(0, 0, 0, 1),
            isNormalized: true
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
        // Create and normalize quaternion
        var quat = _rot
        quat.normalize()

        // Get rotation matrix elements (single source of truth)
        let m = quat.matrixElements

        // Build 4x4 homogeneous transformation matrix in column-major order
        // Matrix layout: [m00 m10 m20 0], [m01 m11 m21 0], [m02 m12 m22 0], [tx ty tz 1]
        let col0 = SIMD4<Float>(m.xx, m.yx, m.zx, 0)
        let col1 = SIMD4<Float>(m.xy, m.yy, m.zy, 0)
        let col2 = SIMD4<Float>(m.xz, m.yz, m.zz, 0)
        let col3 = SIMD4<Float>(_pos.x, _pos.y, _pos.z, 1)

        return simd_float4x4(col0, col1, col2, col3)
    }
}

extension SpatialPose where T == Double {
    /// Convert the pose to a 4x4 homogeneous transformation matrix
    /// - Returns: A 4x4 transformation matrix in column-major order
    public var homogeneousTransform: simd_double4x4 {
        // Create and normalize quaternion
        var quat = _rot
        quat.normalize()

        // Get rotation matrix elements (single source of truth)
        let m = quat.matrixElements

        // Build 4x4 homogeneous transformation matrix in column-major order
        // Matrix layout: [m00 m10 m20 0], [m01 m11 m21 0], [m02 m12 m22 0], [tx ty tz 1]
        let col0 = SIMD4<Double>(m.xx, m.yx, m.zx, 0)
        let col1 = SIMD4<Double>(m.xy, m.yy, m.zy, 0)
        let col2 = SIMD4<Double>(m.xz, m.yz, m.zz, 0)
        let col3 = SIMD4<Double>(_pos.x, _pos.y, _pos.z, 1)

        return simd_double4x4(col0, col1, col2, col3)
    }
}


// Unsafe but explicit Sendable conformance
extension SpatialPose: @unchecked Sendable {}

extension SpatialPose {

    /// Check if the rotation quaternion is normalized.
    ///
    /// Returns the cached normalization flag for the rotation.
    /// This flag is automatically maintained by the Quaternion type:
    /// - Set to `true` after calling `normalize()`
    /// - Set to `false` when any rotation component is modified (qx, qy, qz, qw, or vector)
    ///
    /// - Returns: `true` if the rotation quaternion is normalized, `false` otherwise
    @inlinable
    public var isNormalized: Bool {
        return _rot.isNormalized
    }
}