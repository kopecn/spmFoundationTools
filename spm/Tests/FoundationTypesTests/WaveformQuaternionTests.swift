import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("WaveformQuaternion Initialization")
struct WaveformQuaternionInitializationTests {

    @Test("Basic initialization with all parameters - Float")
    func basicInitializationFloat() {
        let quaternions = [
            FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
            FloatQuaternion(x: 0.0, y: 1.0, z: 0.0, w: 0.0),
            FloatQuaternion(x: 0.0, y: 0.0, z: 1.0, w: 0.0),
        ]
        let dt: Float = 0.01
        let t0 = PrecisionTimestamp()

        let waveform = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: t0)

        #expect(waveform.values.count == 3)
        #expect(waveform.dt == dt)
        #expect(waveform.t0 == t0)
        #expect(waveform.values[0] == quaternions[0])
        #expect(waveform.values[1] == quaternions[1])
        #expect(waveform.values[2] == quaternions[2])
    }

    @Test("Basic initialization with all parameters - Double")
    func basicInitializationDouble() {
        let quaternions = [
            DoubleQuaternion.identity,
            DoubleQuaternion(x: 0.707, y: 0.0, z: 0.0, w: 0.707),
            DoubleQuaternion(x: 0.0, y: 0.707, z: 0.0, w: 0.707),
        ]
        let dt: Double = 0.001
        let t0 = PrecisionTimestamp()

        let waveform = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: t0)

        #expect(waveform.values.count == 3)
        #expect(waveform.dt == dt)
        #expect(waveform.t0 == t0)
        #expect(waveform.values[0] == quaternions[0])
        #expect(waveform.values[1] == quaternions[1])
        #expect(waveform.values[2] == quaternions[2])
    }

    @Test("Values-only initialization")
    func valuesOnlyInitialization() {
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero]
        let waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.values == quaternions)
        #expect(waveform.dt == 1.0)
        #expect(waveform.t0 == nil)
    }

    @Test("Values and dt initialization")
    func valuesAndDtInitialization() {
        let quaternions = [DoubleQuaternion.identity]
        let dt: Double = 0.5
        let waveform = DoubleWaveformQuaternion(values: quaternions, dt: dt)

        #expect(waveform.values == quaternions)
        #expect(waveform.dt == dt)
        #expect(waveform.t0 == nil)
    }

    @Test("Empty quaternion array initialization")
    func emptyQuaternionArrayInitialization() {
        let waveform = FloatWaveformQuaternion(values: [])

        #expect(waveform.values.isEmpty)
        #expect(waveform.dt == 1.0)
        #expect(waveform.t0 == nil)
    }

    @Test("Single quaternion initialization")
    func singleQuaternionInitialization() {
        let quaternion = DoubleQuaternion(x: 0.5, y: 0.5, z: 0.5, w: 0.5)
        let waveform = DoubleWaveformQuaternion(values: [quaternion], dt: 0.1, t0: PrecisionTimestamp())

        #expect(waveform.values.count == 1)
        #expect(waveform.values[0] == quaternion)
        #expect(waveform.dt == 0.1)
        #expect(waveform.t0 != nil)
    }
}

// MARK: - Computed Properties Tests Suite
@Suite("WaveformQuaternion Computed Properties")
struct WaveformQuaternionComputedPropertiesTests {

    @Test("Duration calculation - multiple samples")
    func durationCalculationMultipleSamples() {
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 10)
        let dt: Float = 0.1
        let waveform = FloatWaveformQuaternion(values: quaternions, dt: dt)

        let expectedDuration = Float(quaternions.count - 1) * dt
        #expect(waveform.duration == expectedDuration)
        #expect(abs(waveform.duration - 0.9) < 1e-5)
    }

    @Test("Duration calculation - single sample")
    func durationCalculationSingleSample() {
        let waveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity])

        #expect(waveform.duration == 0)
    }

    @Test("Duration calculation - empty waveform")
    func durationCalculationEmptyWaveform() {
        let waveform = FloatWaveformQuaternion(values: [])

        #expect(waveform.duration == 0)
    }

    @Test("Sampling frequency calculation")
    func samplingFrequencyCalculation() {
        let dt: Double = 0.01  // 10ms
        let waveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity], dt: dt)

        #expect(abs(waveform.samplingFrequency - 100.0) < 1e-10)  // Use epsilon for safety
    }

    @Test("Nyquist frequency calculation")
    func nyquistFrequencyCalculation() {
        let dt: Float = 0.002  // 2ms, 500 Hz sampling
        let waveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: dt)

        #expect(abs(waveform.nyquistFrequency - 250.0) < 2e-5)  // Use epsilon for safety
    }

    @Test("Sample count")
    func sampleCount() {
        let quaternions = Array(repeating: DoubleQuaternion.identity, count: 42)
        let waveform = DoubleWaveformQuaternion(values: quaternions)

        #expect(waveform.sampleCount == 42)
    }

    @Test("Sample count - empty waveform")
    func sampleCountEmptyWaveform() {
        let waveform = FloatWaveformQuaternion(values: [])

        #expect(waveform.sampleCount == 0)
    }
}

// MARK: - Normalization Tests Suite
@Suite("WaveformQuaternion Normalization")
struct WaveformQuaternionNormalizationTests {

    @Test("Are all normalized - true case - Float")
    func areAllNormalizedTrueFloat() {
        let quaternions = [
            FloatQuaternion.identity,
            FloatQuaternion(axis: SIMD3<Float>(1, 0, 0), angle: Float.pi / 4),
            FloatQuaternion(axis: SIMD3<Float>(0, 1, 0), angle: Float.pi / 2),
        ]
        let waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == true)
    }

    @Test("Are all normalized - false case - Float")
    func areAllNormalizedFalseFloat() {
        let quaternions = [
            FloatQuaternion.identity,
            FloatQuaternion(x: 2.0, y: 2.0, z: 2.0, w: 2.0),  // Not normalized
            FloatQuaternion.identity,
        ]
        let waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == false)
    }

    @Test("Are all normalized - Double")
    func areAllNormalizedDouble() {
        let normalizedQuats = [
            DoubleQuaternion.identity,
            DoubleQuaternion(axis: SIMD3<Double>(0, 0, 1), angle: Double.pi / 3),
        ]
        let waveform = DoubleWaveformQuaternion(values: normalizedQuats)

        #expect(waveform.areAllNormalized == true)
    }

    @Test("Normalize mutating method - Float")
    func normalizeMutatingFloat() {
        let quaternions = [
            FloatQuaternion(x: 2.0, y: 0.0, z: 0.0, w: 2.0),
            FloatQuaternion(x: 1.0, y: 1.0, z: 1.0, w: 1.0),
        ]
        var waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == false)

        waveform.normalize()

        #expect(waveform.areAllNormalized == true)

        // Check specific values
        for quaternion in waveform.values {
            let magnitude = sqrt(
                quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z + quaternion.w
                    * quaternion.w
            )
            #expect(abs(magnitude - 1.0) < 1e-6)
        }
    }

    @Test("Normalize mutating method - Double")
    func normalizeMutatingDouble() {
        let quaternions = [
            DoubleQuaternion(x: 3.0, y: 4.0, z: 0.0, w: 0.0),
            DoubleQuaternion(x: 1.0, y: 1.0, z: 1.0, w: 1.0),
        ]
        var waveform = DoubleWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == false)

        waveform.normalize()

        #expect(waveform.areAllNormalized == true)
    }

    @Test("Normalized property - non-mutating")
    func normalizedPropertyNonMutating() {
        let quaternions = [
            FloatQuaternion(x: 2.0, y: 2.0, z: 2.0, w: 2.0),
            FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
        ]
        let originalWaveform = FloatWaveformQuaternion(values: quaternions, dt: 0.1)

        #expect(originalWaveform.areAllNormalized == false)

        let normalizedWaveform = originalWaveform.normalized

        // Original should be unchanged
        #expect(originalWaveform.areAllNormalized == false)

        // New waveform should be normalized
        #expect(normalizedWaveform.areAllNormalized == true)

        // Check that other properties are preserved
        #expect(normalizedWaveform.dt == originalWaveform.dt)
        #expect(normalizedWaveform.t0 == originalWaveform.t0)
        #expect(normalizedWaveform.sampleCount == originalWaveform.sampleCount)
    }

    @Test("Normalize empty waveform")
    func normalizeEmptyWaveform() {
        var waveform = DoubleWaveformQuaternion(values: [])
        waveform.normalize()

        #expect(waveform.values.isEmpty)
        #expect(waveform.areAllNormalized == true)  // Vacuous truth
    }
}

// MARK: - Component Waveforms Tests Suite
@Suite("WaveformQuaternion Component Waveforms")
struct WaveformQuaternionComponentWaveformsTests {

    @Test("Extract component waveforms - Float")
    func extractComponentWaveformsFloat() {
        let quaternions = [
            FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0),
            FloatQuaternion(x: 5.0, y: 6.0, z: 7.0, w: 8.0),
            FloatQuaternion(x: 9.0, y: 10.0, z: 11.0, w: 12.0),
        ]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()
        let waveform = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: t0)

        let components = waveform.componentWaveforms

        // Check x component
        #expect(components.x.values == [1.0, 5.0, 9.0])
        #expect(components.x.dt == dt)
        #expect(components.x.t0 == t0)

        // Check y component
        #expect(components.y.values == [2.0, 6.0, 10.0])
        #expect(components.y.dt == dt)
        #expect(components.y.t0 == t0)

        // Check z component
        #expect(components.z.values == [3.0, 7.0, 11.0])
        #expect(components.z.dt == dt)
        #expect(components.z.t0 == t0)

        // Check w component
        #expect(components.w.values == [4.0, 8.0, 12.0])
        #expect(components.w.dt == dt)
        #expect(components.w.t0 == t0)
    }

    @Test("Extract component waveforms - Double")
    func extractComponentWaveformsDouble() {
        let quaternions = [
            DoubleQuaternion(x: 0.1, y: 0.2, z: 0.3, w: 0.4),
            DoubleQuaternion(x: 0.5, y: 0.6, z: 0.7, w: 0.8),
        ]
        let waveform = DoubleWaveformQuaternion(values: quaternions, dt: 0.05)

        let components = waveform.componentWaveforms

        #expect(components.x.values == [0.1, 0.5])
        #expect(components.y.values == [0.2, 0.6])
        #expect(components.z.values == [0.3, 0.7])
        #expect(components.w.values == [0.4, 0.8])

        // All components should have same temporal properties
        #expect(components.x.dt == 0.05)
        #expect(components.y.dt == 0.05)
        #expect(components.z.dt == 0.05)
        #expect(components.w.dt == 0.05)
    }

    @Test("Component waveforms - empty waveform")
    func componentWaveformsEmptyWaveform() {
        let waveform = FloatWaveformQuaternion(values: [])
        let components = waveform.componentWaveforms

        #expect(components.x.values.isEmpty)
        #expect(components.y.values.isEmpty)
        #expect(components.z.values.isEmpty)
        #expect(components.w.values.isEmpty)
    }

    @Test("Component waveforms - single quaternion")
    func componentWaveformsSingleQuaternion() {
        let quaternion = DoubleQuaternion(x: 1.5, y: 2.5, z: 3.5, w: 4.5)
        let waveform = DoubleWaveformQuaternion(values: [quaternion], dt: 0.01, t0: PrecisionTimestamp())

        let components = waveform.componentWaveforms

        #expect(components.x.values == [1.5])
        #expect(components.y.values == [2.5])
        #expect(components.z.values == [3.5])
        #expect(components.w.values == [4.5])
    }
}

// MARK: - Utility Methods Tests Suite
@Suite("WaveformQuaternion Utility Methods")
struct WaveformQuaternionUtilityMethodsTests {

    @Test("Create from component waveforms - success")
    func createFromComponentWaveformsSuccess() {
        let xValues: [Float] = [1.0, 2.0, 3.0]
        let yValues: [Float] = [4.0, 5.0, 6.0]
        let zValues: [Float] = [7.0, 8.0, 9.0]
        let wValues: [Float] = [10.0, 11.0, 12.0]

        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()

        let xWaveform = Waveform1D<Float, Float>(values: xValues, dt: dt, t0: t0)
        let yWaveform = Waveform1D<Float, Float>(values: yValues, dt: dt, t0: t0)
        let zWaveform = Waveform1D<Float, Float>(values: zValues, dt: dt, t0: t0)
        let wWaveform = Waveform1D<Float, Float>(values: wValues, dt: dt, t0: t0)

        let waveform = FloatWaveformQuaternion.from(x: xWaveform, y: yWaveform, z: zWaveform, w: wWaveform)

        #expect(waveform != nil)
        #expect(waveform!.values.count == 3)
        #expect(waveform!.dt == dt)
        #expect(waveform!.t0 == t0)

        #expect(waveform!.values[0] == FloatQuaternion(x: 1.0, y: 4.0, z: 7.0, w: 10.0))
        #expect(waveform!.values[1] == FloatQuaternion(x: 2.0, y: 5.0, z: 8.0, w: 11.0))
        #expect(waveform!.values[2] == FloatQuaternion(x: 3.0, y: 6.0, z: 9.0, w: 12.0))
    }

    @Test("Create from component waveforms - mismatched counts")
    func createFromComponentWaveformsMismatchedCounts() {
        let xWaveform = Waveform1D<Double, Double>(values: [1.0, 2.0], dt: 0.1)
        let yWaveform = Waveform1D<Double, Double>(values: [3.0, 4.0, 5.0], dt: 0.1)  // Different count
        let zWaveform = Waveform1D<Double, Double>(values: [6.0, 7.0], dt: 0.1)
        let wWaveform = Waveform1D<Double, Double>(values: [8.0, 9.0], dt: 0.1)

        let waveform = DoubleWaveformQuaternion.from(x: xWaveform, y: yWaveform, z: zWaveform, w: wWaveform)

        #expect(waveform == nil)
    }

    @Test("Create from component waveforms - mismatched dt")
    func createFromComponentWaveformsMismatchedDt() {
        let xWaveform = Waveform1D<Float, Float>(values: [1.0, 2.0], dt: 0.1)
        let yWaveform = Waveform1D<Float, Float>(values: [3.0, 4.0], dt: 0.2)  // Different dt
        let zWaveform = Waveform1D<Float, Float>(values: [5.0, 6.0], dt: 0.1)
        let wWaveform = Waveform1D<Float, Float>(values: [7.0, 8.0], dt: 0.1)

        let waveform = FloatWaveformQuaternion.from(x: xWaveform, y: yWaveform, z: zWaveform, w: wWaveform)

        #expect(waveform == nil)
    }
}

// MARK: - Equatable Tests Suite
@Suite("WaveformQuaternion Equatable")
struct WaveformQuaternionEquatableTests {

    @Test("Equality - identical waveforms")
    func equalityIdenticalWaveforms() {
        let quaternions = [FloatQuaternion.identity, FloatQuaternion.zero]
        let dt: Float = 0.1
        let t0 = PrecisionTimestamp()

        let waveform1 = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: t0)
        let waveform2 = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: t0)

        #expect(waveform1 == waveform2)
    }

    @Test("Equality - different values")
    func equalityDifferentValues() {
        let dt: Double = 0.1
        let t0 = PrecisionTimestamp()

        let waveform1 = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity], dt: dt, t0: t0)
        let waveform2 = DoubleWaveformQuaternion(values: [DoubleQuaternion.zero], dt: dt, t0: t0)

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - different dt")
    func equalityDifferentDt() {
        let quaternions = [FloatQuaternion.identity]
        let t0 = PrecisionTimestamp()

        let waveform1 = FloatWaveformQuaternion(values: quaternions, dt: 0.1, t0: t0)
        let waveform2 = FloatWaveformQuaternion(values: quaternions, dt: 0.2, t0: t0)

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - different t0")
    func equalityDifferentT0() {
        let quaternions = [DoubleQuaternion.identity]
        let dt: Double = 0.1

        let waveform1 = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: PrecisionTimestamp(date: .now))
        let waveform2 = DoubleWaveformQuaternion(
            values: quaternions,
            dt: dt,
            t0: PrecisionTimestamp(date: .now.addingTimeInterval(1))
        )

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - nil vs non-nil t0")
    func equalityNilVsNonNilT0() {
        let quaternions = [FloatQuaternion.identity]
        let dt: Float = 0.1

        let waveform1 = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: nil)
        let waveform2 = FloatWaveformQuaternion(values: quaternions, dt: dt, t0: PrecisionTimestamp())

        #expect(waveform1 != waveform2)
    }

    @Test("Equality - both nil t0")
    func equalityBothNilT0() {
        let quaternions = [DoubleQuaternion.identity]
        let dt: Double = 0.1

        let waveform1 = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: nil)
        let waveform2 = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: nil)

        #expect(waveform1 == waveform2)
    }

    @Test("Self equality")
    func selfEquality() {
        let waveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: 0.1)

        #expect(waveform == waveform)
    }
}

// MARK: - Hashable Tests Suite
@Suite("WaveformQuaternion Hashable")
struct WaveformQuaternionHashableTests {

    @Test("Hash consistency")
    func hashConsistency() {
        let waveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: 0.1)
        let hash1 = waveform.hashValue
        let hash2 = waveform.hashValue

        #expect(hash1 == hash2)
    }

    @Test("Equal waveforms have equal hashes")
    func equalWaveformsEqualHashes() {
        let quaternions = [DoubleQuaternion.identity, DoubleQuaternion.zero]
        let dt: Double = 0.1
        let t0 = PrecisionTimestamp()

        let waveform1 = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: t0)
        let waveform2 = DoubleWaveformQuaternion(values: quaternions, dt: dt, t0: t0)

        #expect(waveform1 == waveform2)
        #expect(waveform1.hashValue == waveform2.hashValue)
    }

    @Test("Set operations work correctly")
    func setOperationsWorkCorrectly() {
        let waveform1 = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: 0.1)
        let waveform2 = FloatWaveformQuaternion(values: [FloatQuaternion.zero], dt: 0.1)
        let waveform3 = FloatWaveformQuaternion(values: [FloatQuaternion.identity], dt: 0.1)  // Same as waveform1

        let waveformSet: Set = [waveform1, waveform2, waveform3]

        #expect(waveformSet.count == 2)  // waveform1 and waveform3 should be treated as the same
        #expect(waveformSet.contains(waveform1))
        #expect(waveformSet.contains(waveform2))
        #expect(waveformSet.contains(waveform3))
    }
}

// MARK: - String Representation Tests Suite
@Suite("WaveformQuaternion String Representation")
struct WaveformQuaternionStringRepresentationTests {

    @Test("Description format")
    func descriptionFormat() {
        let quaternions = Array(repeating: FloatQuaternion.identity, count: 5)
        let waveform = FloatWaveformQuaternion(values: quaternions, dt: 0.1)
        let description = waveform.description

        #expect(description.contains("WaveformQuaternion"))
        #expect(description.contains("samples: 5"))
        #expect(description.contains("dt: 0.1"))
        #expect(description.contains("duration: 0.4s"))
    }

    @Test("Debug description format")
    func debugDescriptionFormat() {
        let quaternions = [DoubleQuaternion.identity]
        let t0 = PrecisionTimestamp()
        let waveform = DoubleWaveformQuaternion(values: quaternions, dt: 0.05, t0: t0)
        let debugDescription = waveform.debugDescription

        #expect(debugDescription.contains("WaveformQuaternion<Double>"))
        #expect(debugDescription.contains("samples: 1"))
        #expect(debugDescription.contains("dt: 0.05"))
        #expect(debugDescription.contains("t0:"))
        #expect(debugDescription.contains("duration: 0.0s"))
    }

    @Test("Description with nil t0")
    func descriptionWithNilT0() {
        let waveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity])
        let debugDescription = waveform.debugDescription

        #expect(debugDescription.contains("t0: nil"))
    }

    @Test("Empty waveform description")
    func emptyWaveformDescription() {
        let waveform = DoubleWaveformQuaternion(values: [])
        let description = waveform.description

        #expect(description.contains("samples: 0"))
        #expect(description.contains("duration: 0.0s"))
    }
}

// MARK: - Edge Cases Tests Suite
@Suite("WaveformQuaternion Edge Cases")
struct WaveformQuaternionEdgeCasesTests {

    @Test("Very small dt")
    func verySmallDt() {
        let dt: Float = 1e-9  // 1 nanosecond
        let waveform = FloatWaveformQuaternion(values: [FloatQuaternion.identity, FloatQuaternion.zero], dt: dt)

        #expect(waveform.dt == dt)
        #expect(waveform.duration == dt)
        #expect(abs(waveform.samplingFrequency - 1e9) < 1e-6)  // Use epsilon comparison
    }

    @Test("Very large dt")
    func veryLargeDt() {
        let dt: Double = 86400.0  // 1 day
        let waveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity, DoubleQuaternion.zero], dt: dt)

        #expect(waveform.dt == dt)
        #expect(waveform.duration == dt)
        #expect(abs(waveform.samplingFrequency - (1.0 / 86400.0)) < 1e-10)
    }

    @Test("Large number of samples")
    func largeNumberOfSamples() {
        let largeCount = 10000
        let quaternions = Array(repeating: FloatQuaternion.identity, count: largeCount)
        let waveform = FloatWaveformQuaternion(values: quaternions, dt: 0.001)

        #expect(waveform.sampleCount == largeCount)
        #expect(waveform.duration == Float(largeCount - 1) * 0.001)
        #expect(waveform.areAllNormalized == true)
    }

    @Test("Zero quaternions in waveform")
    func zeroQuaternionsInWaveform() {
        let quaternions = [FloatQuaternion.zero, FloatQuaternion.zero]
        let waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == false)

        // Normalizing zero quaternions should result in identity quaternions
        let normalizedWaveform = waveform.normalized
        for quaternion in normalizedWaveform.values {
            #expect(quaternion == FloatQuaternion.identity)
        }
    }

    @Test("Mixed normalized and unnormalized quaternions")
    func mixedNormalizedUnnormalizedQuaternions() {
        let quaternions = [
            FloatQuaternion.identity,  // Normalized
            FloatQuaternion(x: 2.0, y: 0.0, z: 0.0, w: 0.0),  // Not normalized
            FloatQuaternion(axis: SIMD3<Float>(0, 1, 0), angle: Float.pi / 4),  // Normalized
        ]
        let waveform = FloatWaveformQuaternion(values: quaternions)

        #expect(waveform.areAllNormalized == false)

        let normalizedWaveform = waveform.normalized
        #expect(normalizedWaveform.areAllNormalized == true)
    }

    @Test("Extreme timestamp values")
    func extremeTimestampValues() {
        let quaternions = [DoubleQuaternion.identity]

        // Very old date
        let oldDate = PrecisionTimestamp(date: Date(timeIntervalSince1970: 0))
        let waveformOld = DoubleWaveformQuaternion(values: quaternions, dt: 1.0, t0: oldDate)
        #expect(waveformOld.t0 == oldDate)

        // Very future date
        let futureDate = PrecisionTimestamp(date: Date(timeIntervalSince1970: 4_102_444_800))  // Year 2100
        let waveformFuture = DoubleWaveformQuaternion(values: quaternions, dt: 1.0, t0: futureDate)
        #expect(waveformFuture.t0 == futureDate)
    }
}

// MARK: - Error Handling Tests Suite
@Suite("WaveformQuaternion Error Handling")
struct WaveformQuaternionErrorHandlingTests {

    @Test("CSV import error handling - empty file")
    func csvImportEmptyFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty_quaternions.csv")

        try "".write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try FloatWaveformQuaternion.importFromCSV(from: tempURL)
        }

        // Verify the specific error type by catching it
        do {
            _ = try FloatWaveformQuaternion.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .emptyCSVFile:
                // This is the expected error
                break
            default:
                #expect(Bool(false), "Expected .emptyCSVFile error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("CSV import error handling - invalid format")
    func csvImportInvalidFormat() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid_quaternions.csv")

        // Missing w component
        let invalidCSV = "timestamp,x,y,z\n1.0,2.0,3.0,4.0\n"
        try invalidCSV.write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try DoubleWaveformQuaternion.importFromCSV(from: tempURL)
        }

        // Verify the specific error type and message
        do {
            _ = try DoubleWaveformQuaternion.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .invalidCSVFormat(let expected):
                #expect(expected == "timestamp,x,y,z,w")
            default:
                #expect(Bool(false), "Expected .invalidCSVFormat error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("CSV import error handling - insufficient data")
    func csvImportInsufficientData() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("insufficient_quaternions.csv")

        let csvHeaderOnly = "timestamp,x,y,z,w\n"
        try csvHeaderOnly.write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try FloatWaveformQuaternion.importFromCSV(from: tempURL)
        }

        // Verify the specific error type
        do {
            _ = try FloatWaveformQuaternion.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .insufficientData:
                // This is the expected error
                break
            default:
                #expect(Bool(false), "Expected .insufficientData error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("JSON string conversion error handling")
    func jsonStringConversionErrorHandling() {
        let error = WaveformCodingError.stringConversionFailed
        #expect(error.errorDescription == "Failed to convert JSON data to string")
        #expect(error.localizedDescription == error.errorDescription)
    }

    @Test("Unified error descriptions for quaternions")
    func unifiedErrorDescriptionsForQuaternions() {
        let quaternionSpecificErrors: [WaveformCodingError] = [
            .emptyCSVFile,
            .invalidCSVFormat(expected: "timestamp,x,y,z,w"),
            .insufficientData,
            .stringConversionFailed,
            .invalidFileFormat,
            .missingRequiredField("quaternions"),
            .incompatibleComponentWaveforms,
        ]

        for error in quaternionSpecificErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
