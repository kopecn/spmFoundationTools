import Foundation
import simd

// Convenience typealiases for common use cases
public typealias FloatQuaternion = Quaternion<Float>
public typealias DoubleQuaternion = Quaternion<Double>

/// A quaternion data structure for 3D rotations and orientations.
///
/// `Quaternion` represents a quaternion as a 4-component vector (x, y, z, w) where:
/// - `x`, `y`, `z` represent the vector part (imaginary components)
/// - `w` represents the scalar part (real component)
///
/// Quaternions provide an efficient and stable way to represent rotations in 3D space,
/// avoiding gimbal lock and providing smooth interpolation.
///
/// Example usage:
/// ```swift
/// // Identity quaternion (no rotation)
/// let identity = FloatQuaternion.identity
///
/// // Quaternion from axis-angle
/// let rotation = FloatQuaternion(axis: simd_float3(0, 1, 0), angle: .pi / 4)
///
/// // Quaternion from components
/// let quat = DoubleQuaternion(x: 0, y: 0, z: 0, w: 1)
/// ```
public struct Quaternion<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable> {

    @usableFromInline
    internal var _vector: SIMD4<T>

    /// Cached flag indicating whether this quaternion is normalized
    @usableFromInline
    internal var _isNormalized: Bool

    /// The SIMD4 vector backing this quaternion (x, y, z, w).
    public var vector: SIMD4<T> {
        @inlinable get { _vector }
        @inlinable set { _vector = newValue; _isNormalized = false }
    }

    /// The x component (i coefficient)
    @inlinable
    public var x: T {
        get { _vector.x }
        set {
            _vector.x = newValue
            _isNormalized = false
        }
    }

    /// The y component (j coefficient)
    @inlinable
    public var y: T {
        get { _vector.y }
        set {
            _vector.y = newValue
            _isNormalized = false
        }
    }

    /// The z component (k coefficient)
    @inlinable
    public var z: T {
        get { _vector.z }
        set {
            _vector.z = newValue
            _isNormalized = false
        }
    }

    /// The w component (real part)
    @inlinable
    public var w: T {
        get { _vector.w }
        set {
            _vector.w = newValue
            _isNormalized = false
        }
    }

    /// The imaginary part as a 3D vector (x, y, z)
    @inlinable
    public var imaginary: SIMD3<T> {
        get { SIMD3<T>(_vector.x, _vector.y, _vector.z) }
        set {
            _vector.x = newValue.x
            _vector.y = newValue.y
            _vector.z = newValue.z
            _isNormalized = false
        }
    }

    /// The real part (w component)
    @inlinable
    public var real: T {
        get { _vector.w }
        set {
            _vector.w = newValue
            _isNormalized = false
        }
    }

    // MARK: - Initializers

    /// Initialize a quaternion with individual components
    /// - Parameters:
    ///   - x: The x component (i coefficient)
    ///   - y: The y component (j coefficient)
    ///   - z: The z component (k coefficient)
    ///   - w: The w component (real part)
    ///   - isNormalized: Whether this quaternion is known to be normalized (default: false)
    @inlinable
    public init(x: T, y: T, z: T, w: T, isNormalized: Bool = false) {
        self._vector = SIMD4<T>(x, y, z, w)
        self._isNormalized = isNormalized
    }

    /// Initialize a quaternion from a SIMD4 vector
    /// - Parameters:
    ///   - vector: The SIMD4 vector (x, y, z, w)
    ///   - isNormalized: Whether this quaternion is known to be normalized (default: false)
    @inlinable
    public init(vector: SIMD4<T>, isNormalized: Bool = false) {
        self._vector = vector
        self._isNormalized = isNormalized
    }

    /// Initialize a quaternion from imaginary and real parts
    /// - Parameters:
    ///   - imaginary: The imaginary part as a 3D vector
    ///   - real: The real part
    ///   - isNormalized: Whether this quaternion is known to be normalized (default: false)
    @inlinable
    public init(imaginary: SIMD3<T>, real: T, isNormalized: Bool = false) {
        self._vector = SIMD4<T>(imaginary.x, imaginary.y, imaginary.z, real)
        self._isNormalized = isNormalized
    }

    /// Initialize a quaternion from an axis and angle
    /// - Parameters:
    ///   - axis: The rotation axis (should be normalized)
    ///   - angle: The rotation angle in radians
    @inlinable
    public init(axis: SIMD3<T>, angle: T) where T == Double {
        let halfAngle = angle * 0.5
        var sinHalfAngle: T = 0
        var cosHalfAngle: T = 0
        __sincos(halfAngle, &sinHalfAngle, &cosHalfAngle)

        let normalizedAxis = simd_normalize(axis)

        self._vector = SIMD4<T>(
            normalizedAxis.x * sinHalfAngle,
            normalizedAxis.y * sinHalfAngle,
            normalizedAxis.z * sinHalfAngle,
            cosHalfAngle
        )
        self._isNormalized = true
    }

    /// Initialize a quaternion from an axis and angle
    /// - Parameters:
    ///   - axis: The rotation axis (should be normalized)
    ///   - angle: The rotation angle in radians
    @inlinable
    public init(axis: SIMD3<T>, angle: T) where T == Float {
        let halfAngle = angle * 0.5
        var sinHalfAngle: T = 0
        var cosHalfAngle: T = 0
        __sincosf(halfAngle, &sinHalfAngle, &cosHalfAngle)

        let normalizedAxis = simd_normalize(axis)

        self._vector = SIMD4<T>(
            normalizedAxis.x * sinHalfAngle,
            normalizedAxis.y * sinHalfAngle,
            normalizedAxis.z * sinHalfAngle,
            cosHalfAngle
        )
        self._isNormalized = true
    }

    /// Initialize a quaternion from Euler angles (roll, pitch, yaw)
    /// - Parameters:
    ///   - roll: Rotation around x-axis in radians
    ///   - pitch: Rotation around y-axis in radians
    ///   - yaw: Rotation around z-axis in radians
    @inlinable
    public init(roll: T, pitch: T, yaw: T) where T == Float {
        let halfAngles = SIMD3<T>(roll, pitch, yaw) * 0.5
        var sx: T = 0
        var cx: T = 0
        var sy: T = 0
        var cy: T = 0
        var sz: T = 0
        var cz: T = 0
        __sincosf(halfAngles.x, &sx, &cx)
        __sincosf(halfAngles.y, &sy, &cy)
        __sincosf(halfAngles.z, &sz, &cz)

        self._vector = SIMD4<T>(
            sx * cy * cz - cx * sy * sz,
            cx * sy * cz + sx * cy * sz,
            cx * cy * sz - sx * sy * cz,
            cx * cy * cz + sx * sy * sz
        )
        self._isNormalized = true
    }

    /// Initialize a quaternion from Euler angles (roll, pitch, yaw)
    /// - Parameters:
    ///   - roll: Rotation around x-axis in radians
    ///   - pitch: Rotation around y-axis in radians
    ///   - yaw: Rotation around z-axis in radians
    @inlinable
    public init(roll: T, pitch: T, yaw: T) where T == Double {
        let halfAngles = SIMD3<T>(roll, pitch, yaw) * 0.5
        var sx: T = 0
        var cx: T = 0
        var sy: T = 0
        var cy: T = 0
        var sz: T = 0
        var cz: T = 0
        __sincos(halfAngles.x, &sx, &cx)
        __sincos(halfAngles.y, &sy, &cy)
        __sincos(halfAngles.z, &sz, &cz)

        self._vector = SIMD4<T>(
            sx * cy * cz - cx * sy * sz,
            cx * sy * cz + sx * cy * sz,
            cx * cy * sz - sx * sy * cz,
            cx * cy * cz + sx * sy * sz
        )
        self._isNormalized = true
    }

    // MARK: - Static Properties

    /// The identity quaternion (no rotation)
    @inlinable
    public static var identity: Quaternion<T> {
        Quaternion<T>(vector: SIMD4<T>(0, 0, 0, 1), isNormalized: true)
    }

    /// A zero quaternion (all components are zero)
    @inlinable
    public static var zero: Quaternion<T> {
        Quaternion<T>(vector: SIMD4<T>(0, 0, 0, 0), isNormalized: false)
    }
}

// Unsafe but explicit Sendable conformance
extension Quaternion: @unchecked Sendable {}

// MARK: - Normalization Flag

extension Quaternion {
    /// Returns the cached normalization flag.
    ///
    /// This flag is automatically maintained by the Quaternion type:
    /// - Set to `true` after calling `normalize()` or when created via normalizing initializers
    ///   (axis-angle, Euler angles, identity)
    /// - Set to `false` when any component is modified (x, y, z, w, imaginary, real, vector)
    /// - Defaults to `false` for basic initializers unless explicitly specified
    ///
    /// For actual runtime verification of normalization, use `isUnit` instead,
    /// which computes the magnitude and checks if it's approximately 1.
    @inlinable
    public var isNormalized: Bool {
        _isNormalized
    }
}
