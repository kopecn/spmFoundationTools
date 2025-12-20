import Foundation
import simd

// MARK: - Rotation Matrix Elements
extension Quaternion {
    /// A structure holding rotation matrix elements computed from a quaternion.
    /// Efficiently shares computation of intermediate values when accessing multiple elements.
    ///
    /// The rotation matrix represented by a quaternion (x, y, z, w) is:
    /// ```
    /// | xx  xy  xz |
    /// | yx  yy  yz |
    /// | zx  zy  zz |
    /// ```
    ///
    /// Example usage:
    /// ```swift
    /// let quat = FloatQuaternion(axis: simd_float3(0, 1, 0), angle: .pi / 4)
    /// let elements = quat.matrixElements
    /// print("xy: \(elements.xy), xz: \(elements.xz), yz: \(elements.yz)")
    /// ```
    public struct RotationMatrixElements {
        // Upper triangle and diagonal
        /// The xy element of the rotation matrix: 2(xy - wz)
        public let xy: T

        /// The xz element of the rotation matrix: 2(xz + wy)
        public let xz: T

        /// The yz element of the rotation matrix: 2(yz - wx)
        public let yz: T

        /// The xx diagonal element of the rotation matrix: 1 - 2(y² + z²)
        public let xx: T

        /// The yy diagonal element of the rotation matrix: 1 - 2(x² + z²)
        public let yy: T

        /// The zz diagonal element of the rotation matrix: 1 - 2(x² + y²)
        public let zz: T

        // Lower triangle (symmetric counterparts)
        /// The yx element of the rotation matrix: 2(xy + wz)
        public let yx: T

        /// The zx element of the rotation matrix: 2(xz - wy)
        public let zx: T

        /// The zy element of the rotation matrix: 2(yz + wx)
        public let zy: T

        /// Initialize rotation matrix elements from a quaternion.
        /// Efficiently computes all elements by sharing intermediate calculations.
        @inlinable
        init(quaternion: Quaternion<T>) {
            let two: T = 2

            // Compute squared components (shared across diagonal elements)
            let x2 = quaternion.x * quaternion.x
            let y2 = quaternion.y * quaternion.y
            let z2 = quaternion.z * quaternion.z

            // Compute products for off-diagonal elements
            let xy_prod = quaternion.x * quaternion.y
            let xz_prod = quaternion.x * quaternion.z
            let yz_prod = quaternion.y * quaternion.z

            let wx = quaternion.w * quaternion.x
            let wy = quaternion.w * quaternion.y
            let wz = quaternion.w * quaternion.z

            // Upper triangle off-diagonal elements
            self.xy = two * (xy_prod - wz)
            self.xz = two * (xz_prod + wy)
            self.yz = two * (yz_prod - wx)

            // Lower triangle off-diagonal elements (symmetric counterparts)
            self.yx = two * (xy_prod + wz)
            self.zx = two * (xz_prod - wy)
            self.zy = two * (yz_prod + wx)

            // Diagonal elements
            self.xx = 1 - two * (y2 + z2)
            self.yy = 1 - two * (x2 + z2)
            self.zz = 1 - two * (x2 + y2)
        }
    }

    /// Access all rotation matrix elements efficiently with shared computation.
    ///
    /// When you need multiple matrix elements, use this property to compute them all at once,
    /// which is more efficient than accessing individual element properties separately.
    ///
    /// Example:
    /// ```swift
    /// let elements = quat.matrixElements
    /// let xy = elements.xy
    /// let xz = elements.xz
    /// let yz = elements.yz
    /// ```
    @inlinable
    public var matrixElements: RotationMatrixElements {
        RotationMatrixElements(quaternion: self)
    }

    /// The yx element of the rotation matrix: 2(xy + wz)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var yx: T {
        2 * (x * y + w * z)
    }

    /// The zx element of the rotation matrix: 2(xz - wy)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var zx: T {
        2 * (x * z - w * y)
    }

    /// The zy element of the rotation matrix: 2(yz + wx)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var zy: T {
        2 * (y * z + w * x)
    }


    /// The xy element of the rotation matrix: 2(xy - wz)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var xy: T {
        2 * (x * y - w * z)
    }

    /// The xz element of the rotation matrix: 2(xz + wy)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var xz: T {
        2 * (x * z + w * y)
    }

    /// The yz element of the rotation matrix: 2(yz - wx)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var yz: T {
        2 * (y * z - w * x)
    }

    /// The xx diagonal element of the rotation matrix: 1 - 2(y² + z²)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var xx: T {
        1 - 2 * (y * y + z * z)
    }

    /// The yy diagonal element of the rotation matrix: 1 - 2(x² + z²)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var yy: T {
        1 - 2 * (x * x + z * z)
    }

    /// The zz diagonal element of the rotation matrix: 1 - 2(x² + y²)
    ///
    /// Note: If you need multiple matrix elements, use `matrixElements` instead for better performance.
    @inlinable
    public var zz: T {
        1 - 2 * (x * x + y * y)
    }
}
