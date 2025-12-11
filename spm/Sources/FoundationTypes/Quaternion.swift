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
public struct Quaternion<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable>: Codable {

    /// The SIMD vector representation of the quaternion (x, y, z, w)
    public var vector: SIMD4<T>

    /// The x component (i coefficient)
    @inlinable
    public var x: T {
        get { vector.x }
        set { vector.x = newValue }
    }

    /// The y component (j coefficient)
    @inlinable
    public var y: T {
        get { vector.y }
        set { vector.y = newValue }
    }

    /// The z component (k coefficient)
    @inlinable
    public var z: T {
        get { vector.z }
        set { vector.z = newValue }
    }

    /// The w component (real part)
    @inlinable
    public var w: T {
        get { vector.w }
        set { vector.w = newValue }
    }

    /// The imaginary part as a 3D vector (x, y, z)
    @inlinable
    public var imaginary: SIMD3<T> {
        get { SIMD3<T>(vector.x, vector.y, vector.z) }
        set {
            vector.x = newValue.x
            vector.y = newValue.y
            vector.z = newValue.z
        }
    }

    /// The real part (w component)
    @inlinable
    public var real: T {
        get { vector.w }
        set { vector.w = newValue }
    }

    // MARK: - Initializers

    /// Initialize a quaternion with individual components
    /// - Parameters:
    ///   - x: The x component (i coefficient)
    ///   - y: The y component (j coefficient)
    ///   - z: The z component (k coefficient)
    ///   - w: The w component (real part)
    public init(x: T, y: T, z: T, w: T) {
        self.vector = SIMD4<T>(x, y, z, w)
    }

    /// Initialize a quaternion from a SIMD4 vector
    /// - Parameter vector: The SIMD4 vector (x, y, z, w)
    public init(vector: SIMD4<T>) {
        self.vector = vector
    }

    /// Initialize a quaternion from imaginary and real parts
    /// - Parameters:
    ///   - imaginary: The imaginary part as a 3D vector
    ///   - real: The real part
    public init(imaginary: SIMD3<T>, real: T) {
        self.vector = SIMD4<T>(imaginary.x, imaginary.y, imaginary.z, real)
    }
    /// Initialize a quaternion from an axis and angle
    /// - Parameters:
    ///   - axis: The rotation axis (should be normalized)
    ///   - angle: The rotation angle in radians
    public init(axis: SIMD3<T>, angle: T) where T == Double {
        let halfAngle = angle * 0.5
        let sinHalfAngle = sin(halfAngle)
        let cosHalfAngle = cos(halfAngle)

        let normalizedAxis = simd_normalize(axis)

        self.vector = SIMD4<T>(
            normalizedAxis.x * sinHalfAngle,
            normalizedAxis.y * sinHalfAngle,
            normalizedAxis.z * sinHalfAngle,
            cosHalfAngle
        )
    }

    /// Initialize a quaternion from an axis and angle
    /// - Parameters:
    ///   - axis: The rotation axis (should be normalized)
    ///   - angle: The rotation angle in radians
    public init(axis: SIMD3<T>, angle: T) where T == Float {
        let halfAngle = angle * 0.5
        let sinHalfAngle = sin(halfAngle)
        let cosHalfAngle = cos(halfAngle)

        let normalizedAxis = simd_normalize(axis)

        self.vector = SIMD4<T>(
            normalizedAxis.x * sinHalfAngle,
            normalizedAxis.y * sinHalfAngle,
            normalizedAxis.z * sinHalfAngle,
            cosHalfAngle
        )
    }

    /// Initialize a quaternion from Euler angles (roll, pitch, yaw)
    /// - Parameters:
    ///   - roll: Rotation around x-axis in radians
    ///   - pitch: Rotation around y-axis in radians
    ///   - yaw: Rotation around z-axis in radians
    public init(roll: T, pitch: T, yaw: T) where T == Float {
        let halfAngles = SIMD3<T>(roll, pitch, yaw) * 0.5
        let c = SIMD3<T>(cos(halfAngles.x), cos(halfAngles.y), cos(halfAngles.z))
        let s = SIMD3<T>(sin(halfAngles.x), sin(halfAngles.y), sin(halfAngles.z))

        self.vector = SIMD4<T>(
            s.x * c.y * c.z - c.x * s.y * s.z,
            c.x * s.y * c.z + s.x * c.y * s.z,
            c.x * c.y * s.z - s.x * s.y * c.z,
            c.x * c.y * c.z + s.x * s.y * s.z
        )
    }

    /// Initialize a quaternion from Euler angles (roll, pitch, yaw)
    /// - Parameters:
    ///   - roll: Rotation around x-axis in radians
    ///   - pitch: Rotation around y-axis in radians
    ///   - yaw: Rotation around z-axis in radians
    public init(roll: T, pitch: T, yaw: T) where T == Double {
        let halfAngles = SIMD3<T>(roll, pitch, yaw) * 0.5
        let c = SIMD3<T>(cos(halfAngles.x), cos(halfAngles.y), cos(halfAngles.z))
        let s = SIMD3<T>(sin(halfAngles.x), sin(halfAngles.y), sin(halfAngles.z))

        self.vector = SIMD4<T>(
            s.x * c.y * c.z - c.x * s.y * s.z,
            c.x * s.y * c.z + s.x * c.y * s.z,
            c.x * c.y * s.z - s.x * s.y * c.z,
            c.x * c.y * c.z + s.x * s.y * s.z
        )
    }

    // MARK: - Static Properties

    /// The identity quaternion (no rotation)
    @inlinable
    public static var identity: Quaternion<T> {
        Quaternion<T>(vector: SIMD4<T>(0, 0, 0, 1))
    }

    /// A zero quaternion (all components are zero)
    @inlinable
    public static var zero: Quaternion<T> {
        Quaternion<T>(vector: SIMD4<T>(0, 0, 0, 0))
    }
}

// MARK: - Equatable
extension Quaternion: Equatable {
    @inlinable
    public static func == (lhs: Quaternion<T>, rhs: Quaternion<T>) -> Bool {
        lhs.vector == rhs.vector
    }
}

// MARK: - Hashable
extension Quaternion: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x)
        hasher.combine(vector.y)
        hasher.combine(vector.z)
        hasher.combine(vector.w)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Quaternion: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Quaternion(x: \(x), y: \(y), z: \(z), w: \(w))"
    }

    public var debugDescription: String {
        return "Quaternion<\(T.self)>(x: \(x), y: \(y), z: \(z), w: \(w))"
    }
}

// MARK: - Codable Implementation
extension Quaternion {
    private enum CodingKeys: String, CodingKey {
        case x, y, z, w
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let z = try container.decode(T.self, forKey: .z)
        let w = try container.decode(T.self, forKey: .w)

        self.init(x: x, y: y, z: z, w: w)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
        try container.encode(w, forKey: .w)
    }
}

// Unsafe but explicit Sendable conformance
extension Quaternion: @unchecked Sendable {}

// MARK: - SIMD-Optimized Operations
extension Quaternion where T == Float {
    /// Normalize the quaternion in place to make it a unit quaternion
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
        } else {
            self = .identity
        }
    }

    /// Get a normalized copy of the quaternion
    @inlinable
    public var normalized: Quaternion<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Quaternion<T>(vector: simd_normalize(vector))
        }
        return .identity
    }

    /// The magnitude (length) of the quaternion
    @inlinable
    public var magnitude: T {
        simd_length(vector)
    }

    /// The squared magnitude of the quaternion (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: T {
        simd_length_squared(vector)
    }

    /// Check if this is a unit quaternion (normalized)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(vector) - 1) < 1e-5
    }

    /// Alias for isUnit (more common terminology)
    @inlinable
    public var isNormalized: Bool {
        isUnit
    }
}

extension Quaternion where T == Double {
    /// Normalize the quaternion in place to make it a unit quaternion
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
        } else {
            self = .identity
        }
    }

    /// Get a normalized copy of the quaternion
    @inlinable
    public var normalized: Quaternion<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Quaternion<T>(vector: simd_normalize(vector))
        }
        return .identity
    }

    /// The magnitude (length) of the quaternion
    @inlinable
    public var magnitude: T {
        simd_length(vector)
    }

    /// The squared magnitude of the quaternion (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: T {
        simd_length_squared(vector)
    }

    /// Check if this is a unit quaternion (normalized)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(vector) - 1) < 1e-10
    }

    /// Alias for isUnit (more common terminology)
    @inlinable
    public var isNormalized: Bool {
        isUnit
    }
}
