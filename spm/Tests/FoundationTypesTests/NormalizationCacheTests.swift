import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - O4: `_isNormalized` cache-invalidation regression pins
//
// Every mutating setter on Complex, Position, Quaternion, and SpatialPose
// clears the cached `_isNormalized` flag via a `didSet`-style pattern. These
// tests pin that behavior: construct normalized, mutate one component,
// assert the cached flag flips to `false` while `isUnit` independently
// recomputes (and agrees). They are regression pins expected to currently
// pass — a failure here exposes a real invalidation hole in a setter.

@Suite("Normalization cache invalidation")
struct NormalizationCacheTests {

    // MARK: - Complex

    @Test(
        "testO4_complexSetterInvalidatesIsNormalized",
        arguments: ["storage", "real", "imaginary"]
    )
    func testO4_complexSetterInvalidatesIsNormalized(_ property: String) {
        var z = ComplexDouble(real: 1, imaginary: 0, isNormalized: true)
        #expect(z.isNormalized)
        #expect(z.isUnit)

        switch property {
        case "storage": z.storage = SIMD2(3, 4)
        case "real": z.real = 3
        case "imaginary": z.imaginary = 4
        default: Issue.record("Unhandled Complex property: \(property)")
        }

        #expect(!z.isNormalized)
        #expect(!z.isUnit)
    }

    // MARK: - Position

    @Test(
        "testO4_positionSetterInvalidatesIsNormalized",
        arguments: ["vector", "x", "y", "z"]
    )
    func testO4_positionSetterInvalidatesIsNormalized(_ property: String) {
        var p = DoublePosition(vector: SIMD3(1, 0, 0), isNormalized: true)
        #expect(p.isNormalized)
        #expect(p.isUnit)

        switch property {
        case "vector": p.vector = SIMD3(3, 4, 0)
        case "x": p.x = 3
        case "y": p.y = 4
        case "z": p.z = 5
        default: Issue.record("Unhandled Position property: \(property)")
        }

        #expect(!p.isNormalized)
        #expect(!p.isUnit)
    }

    // MARK: - Quaternion

    @Test(
        "testO4_quaternionSetterInvalidatesIsNormalized",
        arguments: ["vector", "x", "y", "z", "w", "imaginary", "real"]
    )
    func testO4_quaternionSetterInvalidatesIsNormalized(_ property: String) {
        var q = DoubleQuaternion.identity
        #expect(q.isNormalized)
        #expect(q.isUnit)

        switch property {
        case "vector": q.vector = SIMD4(3, 4, 0, 0)
        case "x": q.x = 3
        case "y": q.y = 4
        case "z": q.z = 5
        case "w": q.w = 6
        case "imaginary": q.imaginary = SIMD3(3, 4, 5)
        case "real": q.real = 6
        default: Issue.record("Unhandled Quaternion property: \(property)")
        }

        #expect(!q.isNormalized)
        #expect(!q.isUnit)
    }

    // MARK: - SpatialPose (rotation-linked setters)

    /// `SpatialPose.isNormalized` mirrors the rotation quaternion's cached
    /// flag (see its doc comment: "Set to `false` when any rotation
    /// component is modified") — only the rotation setters participate.
    @Test(
        "testO4_spatialPoseRotationSetterInvalidatesIsNormalized",
        arguments: ["qx", "qy", "qz", "qw"]
    )
    func testO4_spatialPoseRotationSetterInvalidatesIsNormalized(_ property: String) {
        var pose = DoubleSpatialPose.identity
        #expect(pose.isNormalized)
        #expect(pose.quaternion.isUnit)

        switch property {
        case "qx": pose.qx = 3
        case "qy": pose.qy = 4
        case "qz": pose.qz = 5
        case "qw": pose.qw = 6
        default: Issue.record("Unhandled SpatialPose rotation property: \(property)")
        }

        #expect(!pose.isNormalized)
        #expect(!pose.quaternion.isUnit)
    }

    /// Position components on `SpatialPose` do not participate in
    /// `isNormalized` — that flag tracks only the rotation quaternion, never
    /// translation. Pinned explicitly so a future change to that contract is
    /// caught rather than silently assumed.
    @Test(
        "testO4_spatialPosePositionSetterDoesNotAffectIsNormalized",
        arguments: ["x", "y", "z"]
    )
    func testO4_spatialPosePositionSetterDoesNotAffectIsNormalized(_ property: String) {
        var pose = DoubleSpatialPose.identity
        #expect(pose.isNormalized)

        switch property {
        case "x": pose.x = 3
        case "y": pose.y = 4
        case "z": pose.z = 5
        default: Issue.record("Unhandled SpatialPose position property: \(property)")
        }

        #expect(pose.isNormalized)
    }
}
