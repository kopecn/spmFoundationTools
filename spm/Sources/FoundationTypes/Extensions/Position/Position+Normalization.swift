import Foundation
import simd

// MARK: - Normalization Conformance

extension Position: NormalizableFloat where T == Float {

    /// Returns the cached normalization flag.
    ///
    /// This flag is automatically maintained by the Complex type:
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

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
            _isNormalized = true
        } else {
            self.vector = SIMD3(0, 0, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Float {
        simd_length(vector)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Float {
        simd_length_squared(vector)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(vector) - 1) < 1e-10
    }
}

extension Position: NormalizableDouble where T == Double {

    /// Returns the cached normalization flag.
    ///
    /// This flag is automatically maintained by the Complex type:
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

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
            _isNormalized = true
        } else {
            self.vector = SIMD3(0, 0, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Double {
        simd_length(vector)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Double {
        simd_length_squared(vector)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(vector) - 1) < 1e-10
    }
}
