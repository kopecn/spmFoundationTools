import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Matrix Conversion Tests Suite
@Suite("SpatialPose Matrix Conversions")
struct SpatialPoseMatrixConversionTests {

    @Test("Round-trip matrix conversion - Float - identity rotation")
    func roundTripMatrixConversionFloatIdentity() {
        let original = FloatSpatialPose(
            position: SIMD3<Float>(1.0, 2.0, 3.0),
            rotation: SIMD4<Float>(0.0, 0.0, 0.0, 1.0)  // Identity rotation
        )

        let matrix = original.homogeneousTransform
        let reconstructed = FloatSpatialPose(homogeneousTransform: matrix)

        // Check position
        #expect(abs(reconstructed.x - original.x) < 1e-6)
        #expect(abs(reconstructed.y - original.y) < 1e-6)
        #expect(abs(reconstructed.z - original.z) < 1e-6)

        // Check rotation (quaternion may flip sign but represent same rotation)
        let dotProduct =
            original.qx * reconstructed.qx + original.qy * reconstructed.qy + original.qz * reconstructed.qz + original
            .qw * reconstructed.qw
        #expect(abs(abs(dotProduct) - 1.0) < 1e-6)
    }

    @Test("Round-trip matrix conversion - Double - identity rotation")
    func roundTripMatrixConversionDoubleIdentity() {
        let original = DoubleSpatialPose(
            position: SIMD3<Double>(5.5, -2.3, 7.8),
            rotation: SIMD4<Double>(0.0, 0.0, 0.0, 1.0)  // Identity rotation
        )

        let matrix = original.homogeneousTransform
        let reconstructed = DoubleSpatialPose(homogeneousTransform: matrix)

        // Check position
        #expect(abs(reconstructed.x - original.x) < 1e-10)
        #expect(abs(reconstructed.y - original.y) < 1e-10)
        #expect(abs(reconstructed.z - original.z) < 1e-10)

        // Check rotation
        let dotProduct =
            original.qx * reconstructed.qx + original.qy * reconstructed.qy + original.qz * reconstructed.qz + original
            .qw * reconstructed.qw
        #expect(abs(abs(dotProduct) - 1.0) < 1e-10)
    }

    @Test("Round-trip matrix conversion - Float - with rotation")
    func roundTripMatrixConversionFloatRotated() {
        // 90 degree rotation around Y axis
        let original = FloatSpatialPose(
            position: SIMD3<Float>(10.0, 20.0, 30.0),
            rotation: SIMD4<Float>(0.0, 0.7071068, 0.0, 0.7071068)
        )

        let matrix = original.homogeneousTransform
        let reconstructed = FloatSpatialPose(homogeneousTransform: matrix)

        // Check position
        #expect(abs(reconstructed.x - original.x) < 1e-5)
        #expect(abs(reconstructed.y - original.y) < 1e-5)
        #expect(abs(reconstructed.z - original.z) < 1e-5)

        // Check rotation (allowing for sign flip)
        let dotProduct =
            original.qx * reconstructed.qx + original.qy * reconstructed.qy + original.qz * reconstructed.qz + original
            .qw * reconstructed.qw
        #expect(abs(abs(dotProduct) - 1.0) < 1e-5)
    }

    @Test("Round-trip matrix conversion - Double - arbitrary rotation")
    func roundTripMatrixConversionDoubleArbitrary() {
        // Arbitrary normalized quaternion
        let original = DoubleSpatialPose(
            position: SIMD3<Double>(-5.0, 3.0, -8.0),
            rotation: SIMD4<Double>(0.1826, 0.3651, 0.5477, 0.7303)
        )

        let matrix = original.homogeneousTransform
        let reconstructed = DoubleSpatialPose(homogeneousTransform: matrix)

        // Check position
        #expect(abs(reconstructed.x - original.x) < 1e-10)
        #expect(abs(reconstructed.y - original.y) < 1e-10)
        #expect(abs(reconstructed.z - original.z) < 1e-10)

        // Check rotation (allowing for sign flip)
        let dotProduct =
            original.qx * reconstructed.qx + original.qy * reconstructed.qy + original.qz * reconstructed.qz + original
            .qw * reconstructed.qw
        #expect(abs(abs(dotProduct) - 1.0) < 1e-4)
    }

    @Test("Matrix 4x4 identity pose")
    func homogeneousTransformIdentityPose() {
        let identity = FloatSpatialPose.identity
        let matrix = identity.homogeneousTransform

        // Check rotation part (should be identity)
        #expect(abs(matrix.columns.0.x - 1.0) < 1e-6)
        #expect(abs(matrix.columns.1.y - 1.0) < 1e-6)
        #expect(abs(matrix.columns.2.z - 1.0) < 1e-6)

        // Check translation part (should be zero)
        #expect(abs(matrix.columns.3.x) < 1e-6)
        #expect(abs(matrix.columns.3.y) < 1e-6)
        #expect(abs(matrix.columns.3.z) < 1e-6)

        // Check bottom row
        #expect(abs(matrix.columns.3.w - 1.0) < 1e-6)
    }
}

// MARK: - Type Conversion Tests Suite
@Suite("SpatialPose Type Conversions")
struct SpatialPoseTypeConversionTests {

    @Test("Position type conversion - Float")
    func positionConversionFloat() {
        let pose = FloatSpatialPose(
            position: SIMD3<Float>(1.5, 2.5, 3.5),
            rotation: SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        )

        let position = pose.position

        #expect(position.x == 1.5)
        #expect(position.y == 2.5)
        #expect(position.z == 3.5)
        #expect(position == pose._pos)
    }

    @Test("Position type conversion - Double")
    func positionConversionDouble() {
        let pose = DoubleSpatialPose(
            position: SIMD3<Double>(-10.0, 20.0, -30.0),
            rotation: SIMD4<Double>(0.0, 0.0, 0.0, 1.0)
        )

        let position = pose.position

        #expect(position.x == -10.0)
        #expect(position.y == 20.0)
        #expect(position.z == -30.0)
        #expect(position == pose._pos)
    }

    @Test("Quaternion type conversion - Float")
    func quaternionConversionFloat() {
        let pose = FloatSpatialPose(
            position: SIMD3<Float>(0.0, 0.0, 0.0),
            rotation: SIMD4<Float>(0.5, 0.5, 0.5, 0.5)
        )

        let quaternion = pose.quaternion

        #expect(quaternion.x == 0.5)
        #expect(quaternion.y == 0.5)
        #expect(quaternion.z == 0.5)
        #expect(quaternion.w == 0.5)
        #expect(quaternion == pose._rot)
    }

    @Test("Quaternion type conversion - Double")
    func quaternionConversionDouble() {
        let pose = DoubleSpatialPose(
            position: SIMD3<Double>(0.0, 0.0, 0.0),
            rotation: SIMD4<Double>(0.0, 0.7071068, 0.0, 0.7071068)
        )

        let quaternion = pose.quaternion

        #expect(abs(quaternion.x - 0.0) < 1e-10)
        #expect(abs(quaternion.y - 0.7071068) < 1e-6)
        #expect(abs(quaternion.z - 0.0) < 1e-10)
        #expect(abs(quaternion.w - 0.7071068) < 1e-6)
        #expect(quaternion == pose._rot)
    }

    @Test("Round-trip Position and Quaternion types")
    func roundTripPositionQuaternionTypes() {
        let originalPos = FloatPosition(x: 5.0, y: 10.0, z: 15.0)
        let originalQuat = FloatQuaternion(x: 0.1, y: 0.2, z: 0.3, w: 0.9)

        let pose = FloatSpatialPose(position: originalPos, rotation: originalQuat)
        let reconstructedPos = pose.position
        let reconstructedQuat = pose.quaternion

        #expect(reconstructedPos == originalPos)
        #expect(reconstructedQuat == originalQuat)
    }
}

// MARK: - Basic Functionality Tests Suite
@Suite("SpatialPose Basic Functionality")
struct SpatialPoseBasicTests {

    @Test("Initialization from Position and Quaternion")
    func initializationFromPositionQuaternion() {
        let position = DoublePosition(x: 1.0, y: 2.0, z: 3.0)
        let rotation = DoubleQuaternion(x: 0.0, y: 0.0, z: 0.0, w: 1.0)

        let pose = DoubleSpatialPose(position: position, rotation: rotation)

        #expect(pose._pos == position)
        #expect(pose._rot == rotation)
    }

    @Test("Identity pose properties")
    func identityPoseProperties() {
        let identity = FloatSpatialPose.identity

        #expect(identity.x == 0.0)
        #expect(identity.y == 0.0)
        #expect(identity.z == 0.0)
        #expect(identity.qx == 0.0)
        #expect(identity.qy == 0.0)
        #expect(identity.qz == 0.0)
        #expect(identity.qw == 1.0)
    }

    @Test("Matrix from identity preserves identity")
    func matrixFromIdentityPreservesIdentity() {
        let identity = DoubleSpatialPose.identity
        let matrix = identity.homogeneousTransform
        let reconstructed = DoubleSpatialPose(homogeneousTransform: matrix)

        #expect(abs(reconstructed.x) < 1e-10)
        #expect(abs(reconstructed.y) < 1e-10)
        #expect(abs(reconstructed.z) < 1e-10)

        // Quaternion should represent identity rotation
        let dotProduct =
            reconstructed.qx * 0.0 + reconstructed.qy * 0.0 + reconstructed.qz * 0.0 + reconstructed.qw * 1.0
        #expect(abs(abs(dotProduct) - 1.0) < 1e-10)
    }
}
