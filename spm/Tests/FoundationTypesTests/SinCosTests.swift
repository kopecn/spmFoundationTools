import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - sincos(_:) Correctness

@Suite("SinCos Helper")
struct SinCosTests {

    /// Grid of angles covering zero, quadrant boundaries, and extreme magnitudes.
    static let doubleGrid: [Double] = [
        0, .pi / 2, -(.pi / 2), .pi, -(.pi), 1e-9, -1e-9, 1e9, -1e9,
    ]

    static let floatGrid: [Float] = [
        0, .pi / 2, -(.pi / 2), .pi, -(.pi), 1e-9, -1e-9, 1e9, -1e9,
    ]

    @Test("testF5_sincosDoubleMatchesSinCos", arguments: doubleGrid)
    func testF5_sincosDoubleMatchesSinCos(_ x: Double) {
        let (s, c) = sincos(x)
        #if canImport(Darwin)
        // Same libm entry point on Darwin — bitwise identical, not just close.
        #expect(s == Foundation.sin(x))
        #expect(c == Foundation.cos(x))
        #else
        #expect(abs(s - Foundation.sin(x)) <= 1e-15)
        #expect(abs(c - Foundation.cos(x)) <= 1e-15)
        #endif
    }

    @Test("testF5_sincosFloatMatchesSinCos", arguments: floatGrid)
    func testF5_sincosFloatMatchesSinCos(_ x: Float) {
        let (s, c) = sincos(x)
        // `Float` range reduction for large magnitudes (e.g. 1e9) can differ by
        // ~1 ULP between the combined and separate call paths even on Darwin,
        // so use a tight tolerance rather than bitwise equality here (unlike
        // the `Double` grid above, which is exact up to 1e9).
        #expect(abs(s - Foundation.sinf(x)) <= 1e-6)
        #expect(abs(c - Foundation.cosf(x)) <= 1e-6)
    }

    /// Existing-behavior pin: `Quaternion(axis:angle:)` must produce the exact
    /// same bit pattern after routing through the shared `sincos` helper as it
    /// did before the refactor (captured from the pre-refactor `__sincos`
    /// call path on Darwin, axis = (0, 1, 0), angle = 1.2345 rad).
    @Test("testF5_quaternionAxisAngleDoubleUnchanged")
    func testF5_quaternionAxisAngleDoubleUnchanged() {
        let axis = SIMD3<Double>(0, 1, 0)
        let angle = 1.2345
        let quat = DoubleQuaternion(axis: axis, angle: angle)

        #expect(quat.x.bitPattern == 0)
        #expect(quat.y.bitPattern == 4_603_388_539_641_570_628)
        #expect(quat.z.bitPattern == 0)
        #expect(quat.w.bitPattern == 4_605_520_349_359_526_236)
    }

    /// Existing-behavior pin, `Float` overload (axis = (0, 1, 0), angle = 0.5432 rad).
    @Test("testF5_quaternionAxisAngleFloatUnchanged")
    func testF5_quaternionAxisAngleFloatUnchanged() {
        let axis = SIMD3<Float>(0, 1, 0)
        let angle: Float = 0.5432
        let quat = FloatQuaternion(axis: axis, angle: angle)

        #expect(quat.x.bitPattern == 0)
        #expect(quat.y.bitPattern == 1_049_189_145)
        #expect(quat.z.bitPattern == 0)
        #expect(quat.w.bitPattern == 1_064_738_212)
    }
}
