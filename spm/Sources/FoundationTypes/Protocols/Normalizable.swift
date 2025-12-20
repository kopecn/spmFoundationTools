import Foundation

/// Note: - cannot standardize around a single protocol because --> simd + generics has conflict.

public protocol NormalizableDouble {

    /// Normalizes this value in place to unit magnitude.
    ///
    /// After calling this method, `isNormalized` will be `true` and `magnitude` will be approximately 1.0.
    /// For values with near-zero magnitude, the behavior is type-specific but should result in a valid unit value.
    ///
    /// - Complexity: O(1) for SIMD-accelerated types
    @inlinable
    mutating func normalize()

    /// Returns a normalized copy of this value with unit magnitude.
    ///
    /// The returned value will have `isNormalized` set to `true` and `magnitude` approximately 1.0.
    /// The original value is unchanged.
    ///
    /// - Returns: A normalized copy of this value
    /// - Complexity: O(1) for SIMD-accelerated types
    @inlinable
    var normalized: Self { get }

    /// The magnitude (length) of this value.
    ///
    /// For normalized values, this will be approximately 1.0.
    /// Uses SIMD-accelerated square root when available.
    ///
    /// - Returns: The magnitude as a scalar value
    /// - Complexity: O(1)
    @inlinable
    var magnitude: Double { get }

    /// The squared magnitude of this value.
    ///
    /// This is more efficient than `magnitude` as it avoids the square root operation.
    /// Useful for comparisons and when the actual magnitude value isn't needed.
    ///
    /// For normalized values, this will be approximately 1.0.
    ///
    /// - Returns: The squared magnitude as a scalar value
    /// - Complexity: O(1)
    @inlinable
    var magnitudeSquared: Double { get }

    /// Indicates whether this value is a unit value (magnitude approximately 1).
    ///
    /// Uses squared magnitude comparison to avoid expensive square root operations.
    /// The tolerance for "approximately 1" is type-specific (e.g., 1e-5 for Float, 1e-10 for Double).
    ///
    /// - Returns: `true` if the magnitude is approximately 1, `false` otherwise
    /// - Complexity: O(1)
    @inlinable
    var isUnit: Bool { get }

    /// Returns the cached normalization flag.
    ///
    /// This is a performance optimization that tracks whether the value is known to be normalized
    /// without recomputing the magnitude. The flag is:
    /// - Set to `true` after calling `normalize()` or when created via normalizing initializers
    /// - Set to `false` when any component is modified
    /// - Defaults to `false` for basic initializers
    ///
    /// For runtime verification of normalization, use `isUnit` instead, which actually
    /// computes the magnitude and checks if it's approximately 1.
    ///
    /// - Returns: The cached normalization status
    /// - Complexity: O(1)
    @inlinable
    var isNormalized: Bool { get }
}

public protocol NormalizableFloat {

    /// Normalizes this value in place to unit magnitude.
    ///
    /// After calling this method, `isNormalized` will be `true` and `magnitude` will be approximately 1.0.
    /// For values with near-zero magnitude, the behavior is type-specific but should result in a valid unit value.
    ///
    /// - Complexity: O(1) for SIMD-accelerated types
    @inlinable
    mutating func normalize()

    /// Returns a normalized copy of this value with unit magnitude.
    ///
    /// The returned value will have `isNormalized` set to `true` and `magnitude` approximately 1.0.
    /// The original value is unchanged.
    ///
    /// - Returns: A normalized copy of this value
    /// - Complexity: O(1) for SIMD-accelerated types
    @inlinable
    var normalized: Self { get }

    /// The magnitude (length) of this value.
    ///
    /// For normalized values, this will be approximately 1.0.
    /// Uses SIMD-accelerated square root when available.
    ///
    /// - Returns: The magnitude as a scalar value
    /// - Complexity: O(1)
    @inlinable
    var magnitude: Float { get }

    /// The squared magnitude of this value.
    ///
    /// This is more efficient than `magnitude` as it avoids the square root operation.
    /// Useful for comparisons and when the actual magnitude value isn't needed.
    ///
    /// For normalized values, this will be approximately 1.0.
    ///
    /// - Returns: The squared magnitude as a scalar value
    /// - Complexity: O(1)
    @inlinable
    var magnitudeSquared: Float { get }

    /// Indicates whether this value is a unit value (magnitude approximately 1).
    ///
    /// Uses squared magnitude comparison to avoid expensive square root operations.
    /// The tolerance for "approximately 1" is type-specific (e.g., 1e-5 for Float, 1e-10 for Double).
    ///
    /// - Returns: `true` if the magnitude is approximately 1, `false` otherwise
    /// - Complexity: O(1)
    @inlinable
    var isUnit: Bool { get }

    /// Returns the cached normalization flag.
    ///
    /// This is a performance optimization that tracks whether the value is known to be normalized
    /// without recomputing the magnitude. The flag is:
    /// - Set to `true` after calling `normalize()` or when created via normalizing initializers
    /// - Set to `false` when any component is modified
    /// - Defaults to `false` for basic initializers
    ///
    /// For runtime verification of normalization, use `isUnit` instead, which actually
    /// computes the magnitude and checks if it's approximately 1.
    ///
    /// - Returns: The cached normalization status
    /// - Complexity: O(1)
    @inlinable
    var isNormalized: Bool { get }
}
