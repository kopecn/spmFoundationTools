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
public struct Position<T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable> {

    /// The SIMD vector representation of the position (x, y, z)
    public var vector: SIMD3<T> {
        didSet {
            _isNormalized = false
        }
    }

    /// Cached flag indicating whether this complex number is normalized
    @usableFromInline
    internal var _isNormalized: Bool

    /// The x component
    @inlinable
    public var x: T {
        get { vector.x }
        set {
            vector.x = newValue
            _isNormalized = false
        }
    }

    /// The y component
    @inlinable
    public var y: T {
        get { vector.y }
        set {
            vector.y = newValue
            _isNormalized = false
        }
    }

    /// The z component
    @inlinable
    public var z: T {
        get { vector.z }
        set {
            vector.z = newValue
            _isNormalized = false
        }
    }

    /// Convert position to an array of components
    @inlinable
    public var components: [T] {
        return [x, y, z]
    }

    // MARK: - Initializers

    /// Initialize a position with individual components
    /// - Parameters:
    ///   - x: The x component
    ///   - y: The y component
    ///   - z: The z component
    @inlinable
    public init(x: T, y: T, z: T, isNormalized: Bool = false) {
        self.vector = SIMD3<T>(x, y, z)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from a SIMD3 vector
    /// - Parameter vector: The SIMD3 vector (x, y, z)
    @inlinable
    public init(vector: SIMD3<T>, isNormalized: Bool = false) {
        self.vector = vector
        self._isNormalized = isNormalized
    }

    /// Create a position from an array of components
    /// - Parameter components: Array containing [x, y, z] values
    /// - Returns: A new position, or nil if the array doesn't have exactly 3 elements
    @inlinable
    public init?(components: [T], isNormalized: Bool = false) {
        guard components.count == 3 else { return nil }
        self.init(x: components[0], y: components[1], z: components[2])
        self._isNormalized = isNormalized
    }

    /// Initialize a position from cylindrical coordinates
    /// - Parameters:
    ///   - radius: The radial distance from the z-axis
    ///   - angle: The angle in radians from the positive x-axis
    ///   - height: The height (z-coordinate)
    @inlinable
    public init(cylindrical radius: T, angle: T, height: T, isNormalized: Bool = false) where T == Double {
        var sinAngle: T = 0
        var cosAngle: T = 0
        __sincos(angle, &sinAngle, &cosAngle)
        self.vector = SIMD3<T>(radius * cosAngle, radius * sinAngle, height)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from cylindrical coordinates
    /// - Parameters:
    ///   - radius: The radial distance from the z-axis
    ///   - angle: The angle in radians from the positive x-axis
    ///   - height: The height (z-coordinate)
    @inlinable
    public init(cylindrical radius: T, angle: T, height: T, isNormalized: Bool = false) where T == Float {
        var sinAngle: T = 0
        var cosAngle: T = 0
        __sincosf(angle, &sinAngle, &cosAngle)
        self.vector = SIMD3<T>(radius * cosAngle, radius * sinAngle, height)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from spherical coordinates (mathematical/geographic convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude), measured from the positive x-axis
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator (xy-plane).
    ///                Range: -π/2 (south pole) to +π/2 (north pole), with 0 at the equator.
    @inlinable
    public init(spherical radius: T, azimuth: T, elevation: T, isNormalized: Bool = false) where T == Double {
        var sinAzimuth: T = 0
        var cosAzimuth: T = 0
        var sinElevation: T = 0
        var cosElevation: T = 0
        __sincos(azimuth, &sinAzimuth, &cosAzimuth)
        __sincos(elevation, &sinElevation, &cosElevation)
        let radiusXY = radius * cosElevation
        self.vector = SIMD3<T>(radiusXY * cosAzimuth, radiusXY * sinAzimuth, radius * sinElevation)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from spherical coordinates (mathematical/geographic convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: The azimuthal angle in radians (longitude), measured from the positive x-axis
    ///   - elevation: The elevation angle in radians (latitude), measured from the equator (xy-plane).
    ///                Range: -π/2 (south pole) to +π/2 (north pole), with 0 at the equator.
    @inlinable
    public init(spherical radius: T, azimuth: T, elevation: T, isNormalized: Bool = false) where T == Float {
        var sinAzimuth: T = 0
        var cosAzimuth: T = 0
        var sinElevation: T = 0
        var cosElevation: T = 0
        __sincosf(azimuth, &sinAzimuth, &cosAzimuth)
        __sincosf(elevation, &sinElevation, &cosElevation)
        let radiusXY = radius * cosElevation
        self.vector = SIMD3<T>(radiusXY * cosAzimuth, radiusXY * sinAzimuth, radius * sinElevation)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis.
    ///              Represents the longitudinal position around the sphere.
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from the positive
    ///            z-axis following ISO 80000-2:2019 physics convention. 0 is the north pole (+z axis),
    ///            π/2 is the equator (xy-plane), and π is the south pole (-z axis).
    @inlinable
    public init(sphericalISO radius: T, azimuth: T, polar: T, isNormalized: Bool = false) where T == Double {
        var sinAzimuth: T = 0
        var cosAzimuth: T = 0
        var sinPolar: T = 0
        var cosPolar: T = 0
        __sincos(azimuth, &sinAzimuth, &cosAzimuth)
        __sincos(polar, &sinPolar, &cosPolar)
        let radiusXY = radius * sinPolar
        self.vector = SIMD3<T>(radiusXY * cosAzimuth, radiusXY * sinAzimuth, radius * cosPolar)
        self._isNormalized = isNormalized
    }

    /// Initialize a position from spherical coordinates (ISO 80000-2:2019 physics convention)
    /// - Parameters:
    ///   - radius: The radial distance from the origin
    ///   - azimuth: Azimuthal angle in radians (0 to 2π), measured from the positive x-axis.
    ///              Represents the longitudinal position around the sphere.
    ///   - polar: Polar angle (colatitude/zenith angle) in radians (0 to π), measured from the positive
    ///            z-axis following ISO 80000-2:2019 physics convention. 0 is the north pole (+z axis),
    ///            π/2 is the equator (xy-plane), and π is the south pole (-z axis).
    @inlinable
    public init(sphericalISO radius: T, azimuth: T, polar: T, isNormalized: Bool = false) where T == Float {
        var sinAzimuth: T = 0
        var cosAzimuth: T = 0
        var sinPolar: T = 0
        var cosPolar: T = 0
        __sincosf(azimuth, &sinAzimuth, &cosAzimuth)
        __sincosf(polar, &sinPolar, &cosPolar)
        let radiusXY = radius * sinPolar
        self.vector = SIMD3<T>(radiusXY * cosAzimuth, radiusXY * sinAzimuth, radius * cosPolar)
        self._isNormalized = isNormalized
    }
}

// MARK: - Convenience
extension Position where T: BinaryFloatingPoint {
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

// Unsafe but explicit Sendable conformance
extension Position: @unchecked Sendable {}

extension Position {

    /// Returns the cached normalization flag.
    ///
    /// This flag is automatically maintained by the Position type:
    /// - Set to `true` after callsing `normalize()` or when created via normalizing initializers
    /// - Set to `false` when any component is modified (real, imaginary, storage)
    /// - Defaults to `false` for basic initializers unless explicitly specified
    ///
    /// For actual runtime verification of normalization, use `isUnit` instead,
    /// which computes the magnitude and checks if it's approximately 1.
    @inlinable
    public var isNormalized: Bool {
        _isNormalized
    }
}
