import Foundation
import simd

import FoundationInterfaces

// MARK: - Normalization Conformance

extension Position: NormalizableFloat where T == Float {

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            _vector = simd_normalize(_vector)
            _isNormalized = true
        } else {
            self._vector = SIMD3<T>(0, 0, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(_vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Float {
        simd_length(_vector)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Float {
        simd_length_squared(_vector)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        let l = simd_length_squared(_vector)
        return abs(l - 1) < 1e-6 || abs(l) < 1e-6
    }
}

extension Position: NormalizableDouble where T == Double {

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            _vector = simd_normalize(_vector)
            _isNormalized = true
        } else {
            self._vector = SIMD3<T>(0, 0, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(_vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Double {
        simd_length(_vector)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Double {
        simd_length_squared(_vector)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(_vector) - 1) < 1e-10
    }
}
