import Foundation
import simd

// MARK: - Normalization Conformance

extension Quaternion: NormalizableFloat where T == Float {

    /// Normalize the quaternion in place to make it a unit quaternion (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
            _isNormalized = true
        } else {
            self = .identity
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Quaternion<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Quaternion<T>(vector: simd_normalize(vector), isNormalized: true)
        }
        return .identity
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
        abs(simd_length_squared(vector) - 1) < 1e-5
    }
}

extension Quaternion: NormalizableDouble where T == Double {

    /// Normalize the quaternion in place to make it a unit quaternion (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            vector = simd_normalize(vector)
            _isNormalized = true
        } else {
            self = .identity
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Quaternion<T> {
        if simd_length_squared(vector) > T.ulpOfOne * T.ulpOfOne {
            return Quaternion<T>(vector: simd_normalize(vector), isNormalized: true)
        }
        return .identity
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
