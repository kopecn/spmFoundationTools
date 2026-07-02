import Foundation
import simd

import FoundationInterfaces

// MARK: - Normalization Conformance

extension Position: NormalizableFloat where T == Float {

    /// Normalize the position vector in place to unit length (magnitude = 1).
    /// Degenerate (near-zero) vectors are set to zero.
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            _vector = simd_normalize(_vector)
            _isNormalized = true
        } else {
            self._vector = SIMD3<T>(0, 0, 0)
            _isNormalized = false
        }
    }

    /// Returns a normalized copy of the position vector.
    /// Degenerate (near-zero) vectors return a zero vector.
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(_vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: false)
    }

    /// The magnitude (length) of the position vector.
    @inlinable
    public var magnitude: Float {
        simd_length(_vector)
    }

    /// The squared magnitude of the position vector (cheaper than magnitude).
    @inlinable
    public var magnitudeSquared: Float {
        simd_length_squared(_vector)
    }

    /// Whether this is a unit vector (magnitude ≈ 1).
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(_vector) - 1) < 1e-5
    }
}

extension Position: NormalizableDouble where T == Double {

    /// Normalize the position vector in place to unit length (magnitude = 1).
    /// Degenerate (near-zero) vectors are set to zero.
    @inlinable
    public mutating func normalize() {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            _vector = simd_normalize(_vector)
            _isNormalized = true
        } else {
            self._vector = SIMD3<T>(0, 0, 0)
            _isNormalized = false
        }
    }

    /// Returns a normalized copy of the position vector.
    /// Degenerate (near-zero) vectors return a zero vector.
    @inlinable
    public var normalized: Position<T> {
        if simd_length_squared(_vector) > T.ulpOfOne * T.ulpOfOne {
            return Position<T>(vector: simd_normalize(_vector), isNormalized: true)
        }
        return Position<T>(x: 0, y: 0, z: 0, isNormalized: false)
    }

    /// The magnitude (length) of the position vector.
    @inlinable
    public var magnitude: Double {
        simd_length(_vector)
    }

    /// The squared magnitude of the position vector (cheaper than magnitude).
    @inlinable
    public var magnitudeSquared: Double {
        simd_length_squared(_vector)
    }

    /// Whether this is a unit vector (magnitude ≈ 1).
    @inlinable
    public var isUnit: Bool {
        abs(simd_length_squared(_vector) - 1) < 1e-10
    }
}
