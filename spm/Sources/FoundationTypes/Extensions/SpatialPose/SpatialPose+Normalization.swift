import Foundation
import simd

// MARK: - Normalization Conformance

extension SpatialPose: NormalizableFloat where T == Float {

    /// Normalize the quaternion of the SpatialPose in place.
    @inlinable
    public mutating func normalize() {
        if _rot.isNormalized {
            return
        }
        _rot.normalize()
    }

    /// Get a normalized (quaternion) copy of the SpatialPose
    @inlinable
    public var normalized: SpatialPose<T> {
        if _rot.isNormalized {
            return self
        }
        return SpatialPose(position: _pos, rotation: _rot.normalized)
    }

    /// The magnitude (absolute value) of position
    @inlinable
    public var magnitude: Float {
        _pos.magnitude
    }

    /// The squared magnitude of the position (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Float {
        _pos.magnitudeSquared
    }

    /// Check if this is a unit quaternion number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        _rot.isUnit
    }
}

extension SpatialPose: NormalizableDouble where T == Double {

    /// Normalize the quaternion of the SpatialPose in place.
    @inlinable
    public mutating func normalize() {
        if _rot.isNormalized {
            return
        }
        _rot.normalize()
    }

    /// Get a normalized (quaternion) copy of the SpatialPose
    @inlinable
    public var normalized: SpatialPose<T> {
        if _rot.isNormalized {
            return self
        }
        return SpatialPose(position: _pos, rotation: _rot.normalized)
    }

    /// The magnitude (absolute value) of position
    @inlinable
    public var magnitude: Double {
        _pos.magnitude
    }

    /// The squared magnitude of the position (more efficient than magnitude)
    @inlinable
    public var magnitudeSquared: Double {
        _pos.magnitudeSquared
    }

    /// Check if this is a unit quaternion number (normalized, magnitude = 1)
    /// Uses squared magnitude to avoid expensive sqrt operation
    @inlinable
    public var isUnit: Bool {
        _rot.isUnit
    }
}
