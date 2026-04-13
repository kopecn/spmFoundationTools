import Foundation
import simd

import FoundationInterfaces

// MARK: - Normalization Conformance

extension Complex: NormalizableFloat where T == Float {

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_storage) > T.ulpOfOne * T.ulpOfOne {
            _storage = simd_normalize(_storage)
            _isNormalized = true
        } else {
            self._storage = SIMD2(1, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Complex<T> {
        if simd_length_squared(_storage) > T.ulpOfOne * T.ulpOfOne {
            return Complex<T>(vector: simd_normalize(_storage), isNormalized: true)
        }
        return Complex<T>(real: 1, imaginary: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Float {
        simd_length(_storage)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Float {
        simd_length_squared(_storage)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(_storage) - 1) < 1e-5
    }
}

extension Complex: NormalizableDouble where T == Double {

    /// Normalize the complex number in place to make it a unit complex number (magnitude = 1)
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_storage) > T.ulpOfOne * T.ulpOfOne {
            _storage = simd_normalize(_storage)
            _isNormalized = true
        } else {
            self._storage = SIMD2(1, 0)
            _isNormalized = true
        }
    }

    /// Get a normalized copy of the complex number
    @inlinable
    public var normalized: Complex<T> {
        if simd_length_squared(_storage) > T.ulpOfOne * T.ulpOfOne {
            return Complex<T>(vector: simd_normalize(_storage), isNormalized: true)
        }
        return Complex<T>(real: 1, imaginary: 0, isNormalized: true)
    }

    /// The magnitude (absolute value) of the complex number
    @inlinable
    public var magnitude: Double {
        simd_length(_storage)
    }

    /// The squared magnitude of the complex number (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Double {
        simd_length_squared(_storage)
    }

    /// Check if this is a unit complex number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(_storage) - 1) < 1e-10
    }
}
