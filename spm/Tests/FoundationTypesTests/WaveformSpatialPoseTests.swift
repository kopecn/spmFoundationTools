import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("WaveformSpatialPose Initialization")
struct WaveformSpatialPoseInitializationTests {

    @Test("Basic initialization with all parameters - Float")
    func basicInitializationFloat() {
        let positions = [
            FloatPosition(x: 1.0, y: 0.0, z: 0.0),
            FloatPosition(x: 0.0, y: 1.0, z: 0.0),
            FloatPosition(x: 0.0, y: 0.0, z: 1.0),
        ]
        let quaternions = [
            FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
            FloatQuaternion(x: 0.0, y: 1.0, z: 0.0, w: 0.0),
            FloatQuaternion(x: 0.0, y: 0.0, z: 1.0, w: 0.0),
        ]
        let dt: Float = 0.01
        let t0 = PrecisionTimestamp()

        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneMillisecond * 10, t0: t0)

        #expect(waveform.positions.count == 3)
        #expect(waveform.quaternions.count == 3)
        #expect(waveform.dt.secondsAsFloat == dt)
        #expect(waveform.t0 == t0)
        #expect(waveform.positions[0] == positions[0])
        #expect(waveform.quaternions[0] == quaternions[0])
        #expect(waveform.isValid == true)
    }

    @Test("Basic initialization with all parameters - Double")
    func basicInitializationDouble() {
        let positions = [
            DoublePosition.origin,
            DoublePosition.unitX,
        ]
        let quaternions = [
            DoubleQuaternion.identity,
            DoubleQuaternion.zero,
        ]
        let dt: TimeInterval = 0.001
        let t0 = PrecisionTimestamp()

        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dtSeconds: dt, t0: t0)

        #expect(waveform.positions == positions)
        #expect(waveform.quaternions == quaternions)
        #expect(waveform.dt.secondsAsDouble == dt)
        #expect(waveform.t0 == t0)
        #expect(waveform.isValid == true)
    }

    @Test("Values-only initialization")
    func valuesOnlyInitialization() {
        let positions = [FloatPosition.origin, FloatPosition.unitX]
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero]
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.positions == positions)
        #expect(waveform.quaternions == quaternions)
        #expect(waveform.dt.secondsAsFloat == 1.0)
        #expect(waveform.t0 == nil)
        #expect(waveform.isValid == true)
    }

    @Test("Values and dt initialization")
    func valuesAndDtInitialization() {
        let positions = [DoublePosition.origin]
        let quaternions = [DoubleQuaternion.identity]
        let dt: TimeInterval = 0.5
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dtSeconds: dt)

        #expect(waveform.positions == positions)
        #expect(waveform.quaternions == quaternions)
        #expect(waveform.dt.secondsAsDouble == dt)
        #expect(waveform.t0 == nil)
        #expect(waveform.isValid == true)
    }

    @Test("Empty arrays initialization")
    func emptyArraysInitialization() {
        let waveform = FloatWaveformSpatialPose(positions: [], quaternions: [])

        #expect(waveform.positions.isEmpty)
        #expect(waveform.quaternions.isEmpty)
        #expect(waveform.dt.secondsAsFloat == 1.0)
        #expect(waveform.t0 == nil)
        #expect(waveform.isValid == true)
    }

    @Test("Mismatched array sizes")
    func mismatchedArraySizes() {
        let positions = [FloatPosition.origin, FloatPosition.unitX]
        let quaternions = [FloatQuaternion.identity]  // Only one quaternion
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.positions.count == 2)
        #expect(waveform.quaternions.count == 1)
        #expect(waveform.isValid == false)
        #expect(waveform.sampleCount == 1)  // Minimum of both arrays
    }

    @Test("Single pose initialization")
    func singlePoseInitialization() {
        let position = DoublePosition(x: 0.5, y: 0.5, z: 0.5)
        let quaternion = DoubleQuaternion(x: 0.5, y: 0.5, z: 0.5, w: 0.5)
        let waveform = DoubleWaveformSpatialPose(
            positions: [position],
            quaternions: [quaternion],
            dt: .oneDecisecond,
            t0: PrecisionTimestamp()
        )

        #expect(waveform.positions.count == 1)
        #expect(waveform.quaternions.count == 1)
        #expect(waveform.positions[0] == position)
        #expect(waveform.quaternions[0] == quaternion)
        #expect(waveform.dt.secondsAsDouble == 0.1)
        #expect(waveform.t0 != nil)
        #expect(waveform.isValid == true)
    }
}

// MARK: - Computed Properties Tests Suite
@Suite("WaveformSpatialPose Computed Properties")
struct WaveformSpatialPoseComputedPropertiesTests {

    @Test("Duration calculation with multiple samples")
    func durationWithMultipleSamples() {
        let positions = Array(repeating: DoublePosition.origin, count: 5)
        let quaternions = Array(repeating: DoubleQuaternion.identity, count: 5)
        let dt: TimeInterval = 0.1
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dt))

        let expectedDuration = TimeInterval(4) * 0.1  // (5-1) * 0.1
        #expect(waveform.duration.secondsAsDouble == expectedDuration)
    }

    @Test("Duration calculation with single sample")
    func durationWithSingleSample() {
        let waveform = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity],
            dt: .oneDecisecond
        )

        #expect(waveform.duration == .zero)
    }

    @Test("Duration calculation with empty arrays")
    func durationWithEmptyArrays() {
        let waveform = DoubleWaveformSpatialPose(positions: [], quaternions: [], dt: .oneMillisecond)

        #expect(waveform.duration == .zero)
    }

    @Test("Sampling frequency calculation")
    func samplingFrequency() {
        let waveform = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity],
            dt: .oneMillisecond
        )
        let expectedFrequency: Float = 1000.0
    
        #expect(waveform.samplingFrequencyInHz() == expectedFrequency)
    }

    @Test("Nyquist frequency calculation")
    func nyquistFrequency() {
        let waveform = DoubleWaveformSpatialPose(
            positions: [DoublePosition.origin],
            quaternions: [DoubleQuaternion.identity],
            dt: PrecisionTimeInterval(seconds: 0.002)
        )
        let expectedNyquist = (1.0 / 0.002) / 2.0
    
        #expect(waveform.nyquistFrequencyInHz() == expectedNyquist)
    }

    @Test("Sample count with equal arrays")
    func sampleCountEqualArrays() {
        let positions = Array(repeating: FloatPosition.origin, count: 42)
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 42)
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.sampleCount == 42)
        #expect(waveform.isValid == true)
    }

    @Test("Sample count with unequal arrays")
    func sampleCountUnequalArrays() {
        let positions = Array(repeating: DoublePosition.origin, count: 10)
        let quaternions = Array(repeating: DoubleQuaternion.identity, count: 7)
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.sampleCount == 7)  // Minimum
        #expect(waveform.isValid == false)
    }

    @Test("Sample count - empty waveform")
    func sampleCountEmptyWaveform() {
        let waveform = FloatWaveformSpatialPose(positions: [], quaternions: [])

        #expect(waveform.sampleCount == 0)
        #expect(waveform.isValid == true)
    }
}

// MARK: - Normalization Tests Suite
@Suite("WaveformSpatialPose Normalization")
struct WaveformSpatialPoseNormalizationTests {

    @Test("Are all positions unit - true case - Float")
    func areAllPositionsUnitTrueFloat() {
        let positions = [
            FloatPosition.unitX,
            FloatPosition.unitY,
            FloatPosition.unitZ,
        ]
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 3)
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllPositionsUnit == true)
    }

    @Test("Are all positions unit - false case - Float")
    func areAllPositionsUnitFalseFloat() {
        let positions = [
            FloatPosition.unitX,
            FloatPosition(x: 2.0, y: 2.0, z: 2.0),  // Not unit
            FloatPosition.unitZ,
        ]
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 3)
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllPositionsUnit == false)
    }

    @Test("Are all quaternions normalized - true case - Float")
    func areAllQuaternionsNormalizedTrueFloat() {
        let positions = Array(repeating: FloatPosition.origin, count: 3)
        let quaternions = [
            FloatQuaternion.identity,
            FloatQuaternion(axis: SIMD3<Float>(1, 0, 0), angle: Float.pi / 4),
            FloatQuaternion(axis: SIMD3<Float>(0, 1, 0), angle: Float.pi / 2),
        ]
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllQuaternionsNormalized == true)
    }

    @Test("Are all quaternions normalized - false case - Float")
    func areAllQuaternionsNormalizedFalseFloat() {
        let positions = Array(repeating: FloatPosition.origin, count: 3)
        let quaternions = [
            FloatQuaternion.identity,
            FloatQuaternion(x: 2.0, y: 2.0, z: 2.0, w: 2.0),  // Not normalized
            FloatQuaternion.identity,
        ]
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllQuaternionsNormalized == false)
    }

    @Test("Mutating normalize - Float")
    func mutatingNormalizeFloat() {
        let positions = [
            FloatPosition(x: 2.0, y: 0.0, z: 0.0),
            FloatPosition(x: 0.0, y: 3.0, z: 0.0),
        ]
        let quaternions = [
            FloatQuaternion(x: 2.0, y: 2.0, z: 2.0, w: 2.0),
            FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
        ]
        var waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneDecisecond)

        #expect(waveform.areAllPositionsUnit == false)
        #expect(waveform.areAllQuaternionsNormalized == false)

        waveform.normalize()

        #expect(waveform.areAllPositionsUnit == true)
        #expect(waveform.areAllQuaternionsNormalized == true)
        #expect(waveform.dt.secondsAsFloat == 0.1)  // Other properties preserved
    }

    @Test("Normalized copy - Float")
    func normalizedCopyFloat() {
        let positions = [
            FloatPosition(x: 2.0, y: 2.0, z: 2.0),
            FloatPosition(x: 1.0, y: 0.0, z: 0.0),
        ]
        let quaternions = [
            FloatQuaternion(x: 2.0, y: 2.0, z: 2.0, w: 2.0),
            FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
        ]
        let originalWaveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneDecisecond)

        #expect(originalWaveform.areAllPositionsUnit == false)
        #expect(originalWaveform.areAllQuaternionsNormalized == false)

        let normalizedWaveform = originalWaveform.normalized

        // Original should be unchanged
        #expect(originalWaveform.areAllPositionsUnit == false)
        #expect(originalWaveform.areAllQuaternionsNormalized == false)

        // New waveform should be normalized
        #expect(normalizedWaveform.areAllPositionsUnit == true)
        #expect(normalizedWaveform.areAllQuaternionsNormalized == true)

        // Check that other properties are preserved
        #expect(normalizedWaveform.dt == originalWaveform.dt)
        #expect(normalizedWaveform.t0 == originalWaveform.t0)
        #expect(normalizedWaveform.sampleCount == originalWaveform.sampleCount)
    }

    @Test("Are all positions unit - true case - Double")
    func areAllPositionsUnitTrueDouble() {
        let positions = [DoublePosition.unitX, DoublePosition.unitY]
        let quaternions = Array(repeating: DoubleQuaternion.identity, count: 2)
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllPositionsUnit == true)
    }

    @Test("Are all quaternions normalized - true case - Double")
    func areAllQuaternionsNormalizedTrueDouble() {
        let positions = Array(repeating: DoublePosition.origin, count: 2)
        let quaternions = [
            DoubleQuaternion.identity,
            DoubleQuaternion(axis: SIMD3<Double>(0, 0, 1), angle: Double.pi / 3),
        ]
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllQuaternionsNormalized == true)
    }

    @Test("Normalize empty waveform")
    func normalizeEmptyWaveform() {
        var waveform = DoubleWaveformSpatialPose(positions: [], quaternions: [])
        waveform.normalize()

        #expect(waveform.positions.isEmpty)
        #expect(waveform.quaternions.isEmpty)
        #expect(waveform.areAllPositionsUnit == true)  // Vacuous truth
        #expect(waveform.areAllQuaternionsNormalized == true)  // Vacuous truth
    }
}

// MARK: - Component Waveforms Tests Suite
@Suite("WaveformSpatialPose Component Waveforms")
struct WaveformSpatialPoseComponentWaveformsTests {

    @Test("Extract component waveforms - Float")
    func extractComponentWaveformsFloat() {
        let positions = [
            FloatPosition(x: 1.0, y: 2.0, z: 3.0),
            FloatPosition(x: 4.0, y: 5.0, z: 6.0),
            FloatPosition(x: 7.0, y: 8.0, z: 9.0),
        ]
        let quaternions = [
            FloatQuaternion(x: 10.0, y: 11.0, z: 12.0, w: 13.0),
            FloatQuaternion(x: 14.0, y: 15.0, z: 16.0, w: 17.0),
            FloatQuaternion(x: 18.0, y: 19.0, z: 20.0, w: 21.0),
        ]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)

        let components = waveform.componentWaveforms

        // Check position components
        #expect(components.positions.x.values == [1.0, 4.0, 7.0])
        #expect(components.positions.y.values == [2.0, 5.0, 8.0])
        #expect(components.positions.z.values == [3.0, 6.0, 9.0])

        // Check quaternion components
        #expect(components.quaternions.x.values == [10.0, 14.0, 18.0])
        #expect(components.quaternions.y.values == [11.0, 15.0, 19.0])
        #expect(components.quaternions.z.values == [12.0, 16.0, 20.0])
        #expect(components.quaternions.w.values == [13.0, 17.0, 21.0])

        // All components should have same temporal properties
        #expect(components.positions.x.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.positions.y.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.positions.z.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.quaternions.x.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.quaternions.y.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.quaternions.z.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(components.quaternions.w.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))

        #expect(components.positions.x.t0 == t0)
        #expect(components.quaternions.w.t0 == t0)
    }

    @Test("Extract component waveforms - Double")
    func extractComponentWaveformsDouble() {
        let positions = [
            DoublePosition(x: 0.1, y: 0.2, z: 0.3),
            DoublePosition(x: 0.4, y: 0.5, z: 0.6),
        ]
        let quaternions = [
            DoubleQuaternion(x: 0.7, y: 0.8, z: 0.9, w: 1.0),
            DoubleQuaternion(x: 1.1, y: 1.2, z: 1.3, w: 1.4),
        ]
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dtSeconds: 0.05)

        let components = waveform.componentWaveforms

        #expect(components.positions.x.values == [0.1, 0.4])
        #expect(components.positions.y.values == [0.2, 0.5])
        #expect(components.positions.z.values == [0.3, 0.6])
        #expect(components.quaternions.x.values == [0.7, 1.1])
        #expect(components.quaternions.y.values == [0.8, 1.2])
        #expect(components.quaternions.z.values == [0.9, 1.3])
        #expect(components.quaternions.w.values == [1.0, 1.4])

        // All components should have same temporal properties
        #expect(components.positions.x.dt.secondsAsDouble == 0.05)
        #expect(components.quaternions.w.dt.secondsAsDouble == 0.05)
    }

    @Test("Component waveforms - empty waveform")
    func componentWaveformsEmptyWaveform() {
        let waveform = FloatWaveformSpatialPose(positions: [], quaternions: [])
        let components = waveform.componentWaveforms

        #expect(components.positions.x.values.isEmpty)
        #expect(components.positions.y.values.isEmpty)
        #expect(components.positions.z.values.isEmpty)
        #expect(components.quaternions.x.values.isEmpty)
        #expect(components.quaternions.y.values.isEmpty)
        #expect(components.quaternions.z.values.isEmpty)
        #expect(components.quaternions.w.values.isEmpty)
    }

    @Test("Component waveforms - single pose")
    func componentWaveformsSinglePose() {
        let position = DoublePosition(x: 1.5, y: 2.5, z: 3.5)
        let quaternion = DoubleQuaternion(x: 4.5, y: 5.5, z: 6.5, w: 7.5)
        let waveform = DoubleWaveformSpatialPose(
            positions: [position],
            quaternions: [quaternion],
            dt: .oneMillisecond * 10,
            t0: PrecisionTimestamp()
        )

        let components = waveform.componentWaveforms

        #expect(components.positions.x.values == [1.5])
        #expect(components.positions.y.values == [2.5])
        #expect(components.positions.z.values == [3.5])
        #expect(components.quaternions.x.values == [4.5])
        #expect(components.quaternions.y.values == [5.5])
        #expect(components.quaternions.z.values == [6.5])
        #expect(components.quaternions.w.values == [7.5])
    }

    @Test("Position and quaternion waveform extraction")
    func positionQuaternionWaveformExtraction() {
        let positions = [FloatPosition.origin, FloatPosition.unitX]
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)

        let positionWaveform = waveform.positionWaveform
        let quaternionWaveform = waveform.quaternionWaveform

        #expect(positionWaveform.values == positions)
        #expect(positionWaveform.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(positionWaveform.t0 == t0)

        #expect(quaternionWaveform.values == quaternions)
        #expect(quaternionWaveform.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(quaternionWaveform.t0 == t0)
    }
}

// MARK: - Utility Methods Tests Suite
@Suite("WaveformSpatialPose Utility Methods")
struct WaveformSpatialPoseUtilityMethodsTests {

    @Test("Create from separate waveforms - success")
    func createFromSeparateWaveformsSuccess() {
        let positions = [FloatPosition.origin, FloatPosition.unitX, FloatPosition.unitY]
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero, FloatQuaternion.identity]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()

        let positionWaveform = FloatWaveformPosition(values: positions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)
        let quaternionWaveform = FloatWaveformQuaternion(values: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)

        let poseWaveform = FloatWaveformSpatialPose.from(
            positionWaveform: positionWaveform,
            quaternionWaveform: quaternionWaveform
        )

        #expect(poseWaveform != nil)
        #expect(poseWaveform!.positions == positions)
        #expect(poseWaveform!.quaternions == quaternions)
        #expect(poseWaveform!.dt == PrecisionTimeInterval(seconds: TimeInterval(dt)))
        #expect(poseWaveform!.t0 == t0)
        #expect(poseWaveform!.isValid == true)
    }

    @Test("Create from separate waveforms - mismatched counts")
    func createFromSeparateWaveformsMismatchedCounts() {
        let positionWaveform = DoubleWaveformPosition(values: [DoublePosition.origin, DoublePosition.unitX], dt: .oneDecisecond)
        let quaternionWaveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity], dt: .oneDecisecond)  // Different count

        let poseWaveform = DoubleWaveformSpatialPose.from(
            positionWaveform: positionWaveform,
            quaternionWaveform: quaternionWaveform
        )

        #expect(poseWaveform == nil)
    }

    @Test("Create from separate waveforms - mismatched dt")
    func createFromSeparateWaveformsMismatchedDt() {
        let positionWaveform = FloatWaveformPosition(values: [FloatPosition.origin], dt: .oneDecisecond)
        let quaternionWaveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: .oneDecisecond * 2)  // Different dt

        let poseWaveform = FloatWaveformSpatialPose.from(
            positionWaveform: positionWaveform,
            quaternionWaveform: quaternionWaveform
        )

        #expect(poseWaveform == nil)
    }

    @Test("Create from separate waveforms - mismatched t0")
    func createFromSeparateWaveformsMismatchedT0() {
        let t0_1 = PrecisionTimestamp(seconds: 1)
        let t0_2 = PrecisionTimestamp(seconds: 2)  // Different t0

        let positionWaveform = DoubleWaveformPosition(values: [DoublePosition.origin], dt: .oneDecisecond, t0: t0_1)
        let quaternionWaveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity], dt: .oneDecisecond, t0: t0_2)

        let poseWaveform = DoubleWaveformSpatialPose.from(
            positionWaveform: positionWaveform,
            quaternionWaveform: quaternionWaveform
        )

        #expect(poseWaveform == nil)
    }
}

// MARK: - Equatable and Hashable Tests Suite
@Suite("WaveformSpatialPose Equatable and Hashable")
struct WaveformSpatialPoseEquatableHashableTests {

    @Test("Equality - identical waveforms")
    func equalityIdenticalWaveforms() {
        let positions = [FloatPosition.origin, FloatPosition.unitX]
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()

        let waveform1 = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)
        let waveform2 = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0)

        #expect(waveform1 == waveform2)
    }

    @Test("Equality - different positions")
    func equalityDifferentPositions() {
        let quaternions = [DoubleQuaternion.identity]
        let dt: Double = 0.1

        let waveform1 = DoubleWaveformSpatialPose(positions: [DoublePosition.origin], quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dt))
        let waveform2 = DoubleWaveformSpatialPose(positions: [DoublePosition.unitX], quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dt))

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - different quaternions")
    func equalityDifferentQuaternions() {
        let positions = [FloatPosition.origin]
        let dt: Float = 0.1

        let waveform1 = FloatWaveformSpatialPose(positions: positions, quaternions: [FloatQuaternion.identity], dt: PrecisionTimeInterval(seconds: TimeInterval(dt)))
        let waveform2 = FloatWaveformSpatialPose(positions: positions, quaternions: [FloatQuaternion.zero], dt: PrecisionTimeInterval(seconds: TimeInterval(dt)))

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - different dt")
    func equalityDifferentDt() {
        let positions = [DoublePosition.origin]
        let quaternions = [DoubleQuaternion.identity]

        let waveform1 = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneDecisecond)
        let waveform2 = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneDecisecond * 2)

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - different t0")
    func equalityDifferentT0() {
        let positions = [FloatPosition.origin]
        let quaternions = [FloatQuaternion.identity]
        let dt: Float = 0.1
        let t0_1 = PrecisionTimestamp(seconds: 0)
        let t0_2 = PrecisionTimestamp(seconds: 60)

        let waveform1 = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0_1)
        let waveform2 = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: TimeInterval(dt)), t0: t0_2)

        #expect(waveform1 != waveform2)
    }

    @Test("Hashable - equal waveforms have equal hashes")
    func hashableEqualWaveformsEqualHashes() {
        let positions = [DoublePosition.origin]
        let quaternions = [DoubleQuaternion.identity]
        let dt: Double = 0.1

        let waveform1 = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dt))
        let waveform2 = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dt))

        #expect(waveform1 == waveform2)
        #expect(waveform1.hashValue == waveform2.hashValue)
    }

    @Test("Set operations work correctly")
    func setOperationsWorkCorrectly() {
        let waveform1 = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity],
            dt: .oneDecisecond
        )
        let waveform2 = FloatWaveformSpatialPose(
            positions: [FloatPosition.unitX],
            quaternions: [FloatQuaternion.zero],
            dt: .oneDecisecond
        )
        let waveform3 = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity],
            dt: .oneDecisecond
        )  // Same as waveform1

        let waveformSet: Set = [waveform1, waveform2, waveform3]

        #expect(waveformSet.count == 2)  // waveform1 and waveform3 should be treated as the same
        #expect(waveformSet.contains(waveform1))
        #expect(waveformSet.contains(waveform2))
        #expect(waveformSet.contains(waveform3))
    }
}

// MARK: - String Representation Tests Suite
@Suite("WaveformSpatialPose String Representation")
struct WaveformSpatialPoseStringRepresentationTests {

    @Test("Description format")
    func descriptionFormat() {
        let positions = Array(repeating: FloatPosition.origin, count: 5)
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 5)
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneDecisecond)
        let description = waveform.description

        #expect(description.contains("WaveformSpatialPose"))
        #expect(description.contains("samples: 5"))
        #expect(description.contains("dt: 0.1"))
        #expect(description.contains("duration: 0.4"))
    }

    @Test("Debug description format")
    func debugDescriptionFormat() {
        let positions = [DoublePosition.origin]
        let quaternions = [DoubleQuaternion.identity]
        let t0 = PrecisionTimestamp()
        let waveform = DoubleWaveformSpatialPose(positions: positions, quaternions: quaternions, dtSeconds: 0.05, t0: t0)
        let debugDescription = waveform.debugDescription

        #expect(debugDescription.contains("WaveformSpatialPose<Double>"))
        #expect(debugDescription.contains("samples: 1"))
        #expect(debugDescription.contains("dt: 0.05"))
        #expect(debugDescription.contains("t0:"))
        #expect(debugDescription.contains("duration: 0s"))
    }

    @Test("Description with nil t0")
    func descriptionWithNilT0() {
        let waveform = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity]
        )
        let debugDescription = waveform.debugDescription

        #expect(debugDescription.contains("t0: nil"))
    }

    @Test("Empty waveform description")
    func emptyWaveformDescription() {
        let waveform = DoubleWaveformSpatialPose(positions: [], quaternions: [])
        let description = waveform.description

        #expect(description.contains("samples: 0"))
        #expect(description.contains("duration: 0s"))
    }
}

// MARK: - Edge Cases Tests Suite
@Suite("WaveformSpatialPose Edge Cases")
struct WaveformSpatialPoseEdgeCasesTests {

    @Test("Very small dt")
    func verySmallDt() {
        let dt: Float = 1e-9  // 1 nanosecond
        let waveform = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin, FloatPosition.unitX],
            quaternions: [FloatQuaternion.identity, FloatQuaternion.zero],
            dt: PrecisionTimeInterval(seconds: TimeInterval(dt))
        )

        #expect(waveform.dt.secondsAsFloat == dt)
        #expect(waveform.samplingFrequencyInHz() == 1.0 / dt)
        #expect(waveform.duration.secondsAsFloat == dt)
    }

    @Test("Very large dt")
    func veryLargeDt() {
        let dt: Double = 86400  // 1 day
        let waveform = DoubleWaveformSpatialPose(
            positions: [DoublePosition.origin],
            quaternions: [DoubleQuaternion.identity],
            dt: PrecisionTimeInterval(seconds: dt)
        )

        #expect(waveform.dt.secondsAsDouble == dt)
        #expect(waveform.samplingFrequencyInHz() == 1.0 / dt)
    }

    @Test("Large dataset performance", .timeLimit(.minutes(1)))
    func largeDatasetPerformance() {
        let largeCount = 10_000
        let positions = Array(repeating: FloatPosition.origin, count: largeCount)
        let quaternions = Array(repeating: FloatQuaternion.identity, count: largeCount)
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions, dt: .oneMillisecond)

        #expect(waveform.sampleCount == largeCount)
        #expect(waveform.duration.secondsAsFloat == Float(9.999))
        #expect(waveform.isValid == true)
    }

    @Test("Zero positions and quaternions in waveform")
    func zeroPositionsQuaternionsInWaveform() {
        let positions = [FloatPosition.origin, FloatPosition.origin]
        let quaternions = [FloatQuaternion.zero, FloatQuaternion.zero]
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        // Positions of 0,0,0 are considered unit
        #expect(waveform.areAllPositionsUnit == true)
        #expect(waveform.areAllQuaternionsNormalized == false)

        // Normalizing should handle zero values appropriately
        let normalizedWaveform = waveform.normalized
        #expect(normalizedWaveform.positions.count == 2)
        #expect(normalizedWaveform.quaternions.count == 2)
    }

    @Test("Mixed valid and invalid poses")
    func mixedValidInvalidPoses() {
        let positions = [
            FloatPosition.unitX,  // Unit
            FloatPosition(x: 2.0, y: 2.0, z: 2.0),  // Not unit
            FloatPosition.origin,  // Zero magnitude
        ]
        let quaternions = [
            FloatQuaternion.identity,  // Normalized
            FloatQuaternion(x: 2.0, y: 0.0, z: 0.0, w: 0.0),  // Not normalized
            FloatQuaternion.zero,  // Zero magnitude
        ]
        let waveform = FloatWaveformSpatialPose(positions: positions, quaternions: quaternions)

        #expect(waveform.areAllPositionsUnit == false)
        #expect(waveform.areAllQuaternionsNormalized == false)

        let normalizedWaveform = waveform.normalized
        #expect(normalizedWaveform.sampleCount == 3)
    }

    @Test("Type alias usage")
    func typeAliasUsage() {
        let doubleWaveform = DoubleWaveformSpatialPose(
            positions: [DoublePosition.origin],
            quaternions: [DoubleQuaternion.identity]
        )
        let floatWaveform = FloatWaveformSpatialPose(
            positions: [FloatPosition.origin],
            quaternions: [FloatQuaternion.identity]
        )

        #expect(doubleWaveform.sampleCount == 1)
        #expect(floatWaveform.sampleCount == 1)
        #expect(type(of: doubleWaveform) == WaveformSpatialPose<Double>.self)
        #expect(type(of: floatWaveform) == WaveformSpatialPose<Float>.self)
    }
}
