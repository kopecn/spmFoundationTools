import Foundation
import simd

// Convenience typealiases for common use cases
public typealias FloatPosition = Position<Float>
public typealias DoublePosition = Position<Double>

/// A position data structure for 3D spatial coordinates.
///
/// `Position` represents a 3D position as a 3-component vector (x, y, z) where:
/// - `x` represents the position along the x-axis
/// - `y` represents the position along the y-axis
/// - `z` represents the position along the z-axis
///
/// Positions provide an efficient way to represent locations in 3D space,
/// with SIMD optimization for mathematical operations.
///
/// Example usage:
/// ```swift
/// // Origin position
/// let origin = FloatPosition.origin
///
/// // Position from coordinates
/// let position = DoublePosition(x: 1.0, y: 2.0, z: 3.0)
///
/// // Position from SIMD3 vector
/// let vectorPosition = FloatPosition(vector: SIMD3<Float>(4.0, 5.0, 6.0))
/// ```
public struct Position<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable>: Codable {

    /// The SIMD vector representation of the position (x, y, z)
    public var vector: SIMD3<T>

    /// The x component
    @inlinable
    public var x: T {
        get { vector.x }
        set { vector.x = newValue }
    }

    /// The y component
    @inlinable
    public var y: T {
        get { vector.y }
        set { vector.y = newValue }
    }

    /// The z component
    @inlinable
    public var z: T {
        get { vector.z }
        set { vector.z = newValue }
    }

    // MARK: - Initializers

    /// Initialize a position with individual components
    /// - Parameters:
    ///   - x: The x component
    ///   - y: The y component
    ///   - z: The z component
    public init(x: T, y: T, z: T) {
        self.vector = SIMD3<T>(x, y, z)
    }

    /// Initialize a position from a SIMD3 vector
    /// - Parameter vector: The SIMD3 vector (x, y, z)
    public init(vector: SIMD3<T>) {
        self.vector = vector
    }

    /// Initialize a position from cylindrical coordinates
    /// - Parameters:
    ///   - radius: The radial distance from the z-axis
    ///   - angle: The angle in radians from the positive x-axis
    ///   - height: The height (z-coordinate)
    public init(cylindrical radius: T, angle: T, height: T) where T == Double {
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        self.vector = SIMD3<T>(x, y, height)
    }

    /// Initialize a position from cylindrical coordinates
    /// - Parameters:
    ///   - radius: The radial distance from the z-axis
    ///   - angle: The angle in radians from the positive x-axis
    ///   - height: The height (z-coordinate)
    public init(cylindrical radius: T, angle: T, height: T) where T == Float {
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        self.vector = SIMD3<T>(x, y, height)
    }

    /// Initialize a position from spherical coordinates (mathematical/geographic convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude), measured from the positive x-axis
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator (xy-plane).
    ///                Range: -π/2 (south pole) to +π/2 (north pole), with 0 at the equator.
    public init(spherical radius: T, azimuth: T, elevation: T) where T == Double {
        let x = radius * cos(elevation) * cos(azimuth)
        let y = radius * cos(elevation) * sin(azimuth)
        let z = radius * sin(elevation)
        self.vector = SIMD3<T>(x, y, z)
    }

    /// Initialize a position from spherical coordinates (mathematical/geographic convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude), measured from the positive x-axis
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator (xy-plane).
    ///                Range: -π/2 (south pole) to +π/2 (north pole), with 0 at the equator.
    public init(spherical radius: T, azimuth: T, elevation: T) where T == Float {
        let x = radius * cos(elevation) * cos(azimuth)
        let y = radius * cos(elevation) * sin(azimuth)
        let z = radius * sin(elevation)
        self.vector = SIMD3<T>(x, y, z)
    }

    /// Initialize a position from spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis.
    ///              Represents the longitudinal position around the sphere.
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from the positive
    ///            z-axis following ISO 80000-2:2019 physics convention. 0 is the north pole (+z axis),
    ///            π/2 is the equator (xy-plane), and π is the south pole (-z axis).
    public init(sphericalISO radius: T, azimuth: T, polar: T) where T == Double {
        let x = radius * sin(polar) * cos(azimuth)
        let y = radius * sin(polar) * sin(azimuth)
        let z = radius * cos(polar)
        self.vector = SIMD3<T>(x, y, z)
    }

    /// Initialize a position from spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis.
    ///              Represents the longitudinal position around the sphere.
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from the positive
    ///            z-axis following ISO 80000-2:2019 physics convention. 0 is the north pole (+z axis),
    ///            π/2 is the equator (xy-plane), and π is the south pole (-z axis).
    public init(sphericalISO radius: T, azimuth: T, polar: T) where T == Float {
        let x = radius * sin(polar) * cos(azimuth)
        let y = radius * sin(polar) * sin(azimuth)
        let z = radius * cos(polar)
        self.vector = SIMD3<T>(x, y, z)
    }

    // MARK: - Static Properties

    /// The origin position (0, 0, 0)
    @inlinable
    public static var origin: Position<T> {
        return Position<T>(vector: SIMD3<T>(0, 0, 0))
    }

    /// Unit position along the x-axis (1, 0, 0)
    @inlinable
    public static var unitX: Position<T> {
        return Position<T>(vector: SIMD3<T>(1, 0, 0))
    }

    /// Unit position along the y-axis (0, 1, 0)
    @inlinable
    public static var unitY: Position<T> {
        return Position<T>(vector: SIMD3<T>(0, 1, 0))
    }

    /// Unit position along the z-axis (0, 0, 1)
    @inlinable
    public static var unitZ: Position<T> {
        return Position<T>(vector: SIMD3<T>(0, 0, 1))
    }
}

// MARK: - Equatable
extension Position: Equatable {
    public static func == (lhs: Position<T>, rhs: Position<T>) -> Bool {
        return lhs.vector == rhs.vector
    }
}

// MARK: - Hashable
extension Position: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x)
        hasher.combine(vector.y)
        hasher.combine(vector.z)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Position: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Position(x: \(x), y: \(y), z: \(z))"
    }

    public var debugDescription: String {
        return "Position<\(T.self)>(x: \(x), y: \(y), z: \(z))"
    }
}

// MARK: - Codable Implementation
extension Position {
    private enum CodingKeys: String, CodingKey {
        case x, y, z
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let z = try container.decode(T.self, forKey: .z)

        self.init(x: x, y: y, z: z)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
    }
}

// Unsafe but explicit Sendable conformance
extension Position: @unchecked Sendable {}

// MARK: - Collection Operations
extension Position {

    /// Create a position from an array of components
    /// - Parameter components: Array containing [x, y, z] values
    /// - Returns: A new position, or nil if the array doesn't have exactly 3 elements
    public init?(components: [T]) {
        guard components.count == 3 else { return nil }
        self.init(x: components[0], y: components[1], z: components[2])
    }

    /// Convert position to an array of components
    public var components: [T] {
        return [x, y, z]
    }
}

// MARK: - Computed Properties
extension Position where T == Float {

    /// The magnitude (distance from origin) of the position
    @inlinable
    public var magnitude: T {
        return simd_length(vector)
    }

    /// The squared magnitude of the position
    @inlinable
    public var magnitudeSquared: T {
        return simd_length_squared(vector)
    }

    /// Get a normalized copy of the position (unit vector)
    @inlinable
    public var normalized: Position<T> {
        let mag = magnitude
        if mag > T.ulpOfOne {
            return Position<T>(vector: simd_normalize(vector))
        } else {
            return .origin
        }
    }

    /// Normalize the position in place to make it a unit vector
    @inlinable
    public mutating func normalize() {
        let mag = magnitude
        if mag > T.ulpOfOne {
            vector = simd_normalize(vector)
        } else {
            self = .origin
        }
    }

    /// Check if this is a unit position (magnitude ≈ 1)
    @inlinable
    public var isUnit: Bool {
        let mag = magnitude
        return abs(mag - 1) < T.ulpOfOne * 10
    }

    /// Convert to cylindrical coordinates (radius, angle, height)
    public var cylindrical: (radius: T, angle: T, height: T) {
        let radius = sqrt(x * x + y * y)
        let angle = atan2(y, x)
        return (radius: radius, angle: angle, height: z)
    }

    /// Convert to spherical coordinates (mathematical/geographic convention)
    /// - Returns: A tuple with (radius, azimuth, elevation) where:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude)
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator
    public var spherical: (radius: T, azimuth: T, elevation: T) {
        let radius = magnitude
        let azimuth = atan2(y, x)
        let elevation = asin(z / radius)
        return (radius: radius, azimuth: azimuth, elevation: elevation)
    }

    /// Convert to spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Returns: A tuple with (radius, azimuth, polar) where:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from +z axis
    public var sphericalISO: (radius: T, azimuth: T, polar: T) {
        let radius = magnitude
        let azimuth = atan2(y, x)
        let polar = acos(z / radius)
        return (radius: radius, azimuth: azimuth, polar: polar)
    }
}

// MARK: - Computed Properties
extension Position where T == Double {

    /// The magnitude (distance from origin) of the position
    @inlinable
    public var magnitude: T {
        return simd_length(vector)
    }

    /// The squared magnitude of the position
    @inlinable
    public var magnitudeSquared: T {
        return simd_length_squared(vector)
    }

    /// Get a normalized copy of the position (unit vector)
    @inlinable
    public var normalized: Position<T> {
        let mag = magnitude
        if mag > T.ulpOfOne {
            return Position<T>(vector: simd_normalize(vector))
        } else {
            return .origin
        }
    }

    /// Normalize the position in place to make it a unit vector
    @inlinable
    public mutating func normalize() {
        let mag = magnitude
        if mag > T.ulpOfOne {
            vector = simd_normalize(vector)
        } else {
            self = .origin
        }
    }

    /// Check if this is a unit position (magnitude ≈ 1)
    @inlinable
    public var isUnit: Bool {
        let mag = magnitude
        return abs(mag - 1) < T.ulpOfOne * 10
    }

    /// Convert to cylindrical coordinates (radius, angle, height)
    public var cylindrical: (radius: T, angle: T, height: T) {
        let radius = sqrt(x * x + y * y)
        let angle = atan2(y, x)
        return (radius: radius, angle: angle, height: z)
    }

    /// Convert to spherical coordinates (mathematical/geographic convention)
    /// - Returns: A tuple with (radius, azimuth, elevation) where:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude)
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator
    public var spherical: (radius: T, azimuth: T, elevation: T) {
        let radius = magnitude
        let azimuth = atan2(y, x)
        let elevation = asin(z / radius)
        return (radius: radius, azimuth: azimuth, elevation: elevation)
    }

    /// Convert to spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Returns: A tuple with (radius, azimuth, polar) where:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from +z axis
    public var sphericalISO: (radius: T, azimuth: T, polar: T) {
        let radius = magnitude
        let azimuth = atan2(y, x)
        let polar = acos(z / radius)
        return (radius: radius, azimuth: azimuth, polar: polar)
    }
}
