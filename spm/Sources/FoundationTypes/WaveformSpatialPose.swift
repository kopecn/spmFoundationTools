import Foundation
import simd

// Convenience typealiases for common use cases
public typealias DoubleWaveformSpatialPose = WaveformSpatialPose<Double>
public typealias FloatWaveformSpatialPose = WaveformSpatialPose<Float>

/// A pose waveform data structure representing time-series spatial pose data (position + orientation).
///
/// `WaveformSpatialPose` stores uniformly sampled pose values (position and quaternion) with their temporal characteristics,
/// making it suitable for motion tracking, pose analysis, and spatial-orientation time-series data.
///
/// Example usage:
/// ```swift
/// let startTime = PrecisionTimestamp()
/// let samplingInterval = 0.001 // 1ms sampling
/// let positions: [FloatPosition] = [
///     FloatPosition.origin,
///     FloatPosition(x: 0.1, y: 0.0, z: 0.0),
///     FloatPosition(x: 0.2, y: 0.1, z: 0.0)
/// ]
/// let quaternions: [FloatQuaternion] = [
///     FloatQuaternion.identity,
///     FloatQuaternion(x: 0.1, y: 0.0, z: 0.0, w: 0.995),
///     FloatQuaternion(x: 0.2, y: 0.0, z: 0.0, w: 0.98)
/// ]
/// var waveform = WaveformSpatialPose(positions: positions, quaternions: quaternions, dt: samplingInterval, t0: startTime)
///
/// // Double pose waveform
/// var doubleWaveform = DoubleWaveformSpatialPose(positions: [DoublePosition.origin], quaternions: [DoubleQuaternion.identity])
/// ```
public struct WaveformSpatialPose<T: BinaryFloatingPoint & SIMDScalar & Sendable>: Sendable {
    /// The sampled position values of the waveform
    public var positions: [Position<T>]

    /// The sampled quaternion values of the waveform
    public var quaternions: [Quaternion<T>]

    /// The time interval between consecutive samples
    public var dt: PrecisionTimeInterval

    /// The absolute start time of the first sample
    public var t0: PrecisionTimestamp?

    /// Initialize a pose waveform
    /// - Parameters:
    ///   - positions: The sampled position values
    ///   - quaternions: The sampled quaternion values
    ///   - dt: The time interval between samples (must be positive, defaults to 1 second)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    /// - Note: If positions and quaternions have different counts, `isValid` will be false and `sampleCount` will return the minimum
    public init(
        positions: [Position<T>],
        quaternions: [Quaternion<T>],
        dt: PrecisionTimeInterval = PrecisionTimeInterval(seconds: 1.0),
        t0: PrecisionTimestamp? = nil
    ) {
        precondition(dt > .zero, "Time interval (dt) must be positive, got \(dt)")
        self.positions = positions
        self.quaternions = quaternions
        self.dt = dt
        self.t0 = t0
    }

    /// Convenience initializer with dt in seconds as Double
    /// - Parameters:
    ///   - positions: The sampled position values
    ///   - quaternions: The sampled quaternion values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(
        positions: [Position<T>],
        quaternions: [Quaternion<T>],
        dtSeconds: Double,
        t0: PrecisionTimestamp? = nil
    ) {
        self.init(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    /// Convenience initializer with dt in seconds as Float
    /// - Parameters:
    ///   - positions: The sampled position values
    ///   - quaternions: The sampled quaternion values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(positions: [Position<T>], quaternions: [Quaternion<T>], dtSeconds: Float, t0: PrecisionTimestamp? = nil)
    {
        self.init(positions: positions, quaternions: quaternions, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    /// Initialize from an array of SpatialPose instances
    /// - Parameters:
    ///   - poses: Array of SpatialPose instances to convert to waveform
    ///   - dt: The time interval between samples (must be positive, defaults to 1 second)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    public init(poses: [SpatialPose<T>], dt: PrecisionTimeInterval = PrecisionTimeInterval(seconds: 1.0), t0: PrecisionTimestamp? = nil)
    {
        precondition(dt > .zero, "Time interval (dt) must be positive, got \(dt)")
        self.positions = poses.map { $0.position }
        self.quaternions = poses.map { $0.quaternion }
        self.dt = dt
        self.t0 = t0
    }

    /// Convenience initializer from SpatialPose array with dt in seconds as Double
    /// - Parameters:
    ///   - poses: Array of SpatialPose instances to convert to waveform
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(poses: [SpatialPose<T>], dtSeconds: Double, t0: PrecisionTimestamp? = nil) {
        self.init(poses: poses, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    /// Convenience initializer from SpatialPose array with dt in seconds as Float
    /// - Parameters:
    ///   - poses: Array of SpatialPose instances to convert to waveform
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(poses: [SpatialPose<T>], dtSeconds: Float, t0: PrecisionTimestamp? = nil) {
        self.init(poses: poses, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    // MARK: - Computed Properties (Available to all pose types)

    /// Get the total duration of the waveform as a PrecisionTimeInterval
    public var duration: PrecisionTimeInterval {
        guard positions.count > 1 else { return .zero }
        return dt * positions.count
    }

    // FIXME: -- 
    // /// Get the total duration of the waveform in seconds as the specified floating point type
    // public func durationInSeconds<U: BinaryFloatingPoint>() -> U {
    //     guard sampleCount > 1 else { return 0 }
    //     let dtSeconds: U = dt.asFloatingPoint()
    //     return U(sampleCount - 1) * dtSeconds
    // }

    // FIXME: -- 
    // /// Get the sampling frequency (Hz) in the specified floating point type
    // public func samplingFrequencyInHz<U: BinaryFloatingPoint>() -> U {
    //     let dtSeconds: U = dt.asFloatingPoint()
    //     return 1.0 / dtSeconds
    // }

    // FIXME: -- 
    // /// Get the Nyquist frequency (Hz) in the specified floating point type
    // public func nyquistFrequencyInHz<U: BinaryFloatingPoint>() -> U {
    //     return samplingFrequencyInHz() / 2.0
    // }

    /// Get the number of samples (minimum of positions and quaternions count)
    public var sampleCount: Int {
        return min(positions.count, quaternions.count)
    }

    /// Check if positions and quaternions arrays have matching counts
    public var isValid: Bool {
        return positions.count == quaternions.count
    }
}

// MARK: - Computed Properties for Float Types
extension WaveformSpatialPose where T == Float {

    /// Check if all positions in the waveform are unit positions (magnitude ≈ 1)
    public var areAllPositionsUnit: Bool {
        return positions.allSatisfy { $0.isUnit }
    }

    /// Check if all quaternions in the waveform are normalized (unit quaternions)
    public var areAllQuaternionsNormalized: Bool {
        return quaternions.allSatisfy { $0.isUnit }
    }

    /// Normalize all positions and quaternions in the waveform
    public mutating func normalize() {
        for i in 0..<positions.count {
            positions[i].normalize()
        }
        for i in 0..<quaternions.count {
            quaternions[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform
    public var normalized: WaveformSpatialPose<T> {
        let normalizedPositions = positions.map { $0.normalized }
        let normalizedQuaternions = quaternions.map { $0.normalized }
        return WaveformSpatialPose<T>(
            positions: normalizedPositions,
            quaternions: normalizedQuaternions,
            dt: dt,
            t0: t0
        )
    }

    /// Extract component waveforms for positions (x, y, z) and quaternions (x, y, z, w)
    public var componentWaveforms:
        (
            positions: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>),
            quaternions: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>, w: Waveform1D<T>)
        )
    {
        let posXValues = positions.map { $0.x }
        let posYValues = positions.map { $0.y }
        let posZValues = positions.map { $0.z }

        let quatXValues = quaternions.map { $0.x }
        let quatYValues = quaternions.map { $0.y }
        let quatZValues = quaternions.map { $0.z }
        let quatWValues = quaternions.map { $0.w }

        return (
            positions: (
                x: Waveform1D<T>(values: posXValues, dt: dt, t0: t0),
                y: Waveform1D<T>(values: posYValues, dt: dt, t0: t0),
                z: Waveform1D<T>(values: posZValues, dt: dt, t0: t0)
            ),
            quaternions: (
                x: Waveform1D<T>(values: quatXValues, dt: dt, t0: t0),
                y: Waveform1D<T>(values: quatYValues, dt: dt, t0: t0),
                z: Waveform1D<T>(values: quatZValues, dt: dt, t0: t0),
                w: Waveform1D<T>(values: quatWValues, dt: dt, t0: t0)
            )
        )
    }

    /// Get the position waveform component
    public var positionWaveform: WaveformPosition<T> {
        return WaveformPosition<T>(values: positions, dt: dt, t0: t0)
    }

    /// Get the quaternion waveform component
    public var quaternionWaveform: WaveformQuaternion<T> {
        return WaveformQuaternion<T>(values: quaternions, dt: dt, t0: t0)
    }
}

// MARK: - Computed Properties for Double Types
extension WaveformSpatialPose where T == Double {

    /// Check if all positions in the waveform are unit positions (magnitude ≈ 1)
    public var areAllPositionsUnit: Bool {
        return positions.allSatisfy { $0.isUnit }
    }

    /// Check if all quaternions in the waveform are normalized (unit quaternions)
    public var areAllQuaternionsNormalized: Bool {
        return quaternions.allSatisfy { $0.isUnit }
    }

    /// Normalize all positions and quaternions in the waveform
    public mutating func normalize() {
        for i in 0..<positions.count {
            positions[i].normalize()
        }
        for i in 0..<quaternions.count {
            quaternions[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform
    public var normalized: WaveformSpatialPose<T> {
        let normalizedPositions = positions.map { $0.normalized }
        let normalizedQuaternions = quaternions.map { $0.normalized }
        return WaveformSpatialPose<T>(
            positions: normalizedPositions,
            quaternions: normalizedQuaternions,
            dt: dt,
            t0: t0
        )
    }

    /// Extract component waveforms for positions (x, y, z) and quaternions (x, y, z, w)
    public var componentWaveforms:
        (
            positions: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>),
            quaternions: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>, w: Waveform1D<T>)
        )
    {
        let posXValues = positions.map { $0.x }
        let posYValues = positions.map { $0.y }
        let posZValues = positions.map { $0.z }

        let quatXValues = quaternions.map { $0.x }
        let quatYValues = quaternions.map { $0.y }
        let quatZValues = quaternions.map { $0.z }
        let quatWValues = quaternions.map { $0.w }

        return (
            positions: (
                x: Waveform1D<T>(values: posXValues, dt: dt, t0: t0),
                y: Waveform1D<T>(values: posYValues, dt: dt, t0: t0),
                z: Waveform1D<T>(values: posZValues, dt: dt, t0: t0)
            ),
            quaternions: (
                x: Waveform1D<T>(values: quatXValues, dt: dt, t0: t0),
                y: Waveform1D<T>(values: quatYValues, dt: dt, t0: t0),
                z: Waveform1D<T>(values: quatZValues, dt: dt, t0: t0),
                w: Waveform1D<T>(values: quatWValues, dt: dt, t0: t0)
            )
        )
    }

    /// Get the position waveform component
    public var positionWaveform: WaveformPosition<T> {
        return WaveformPosition<T>(values: positions, dt: dt, t0: t0)
    }

    /// Get the quaternion waveform component
    public var quaternionWaveform: WaveformQuaternion<T> {
        return WaveformQuaternion<T>(values: quaternions, dt: dt, t0: t0)
    }
}

// MARK: - Utility Methods
extension WaveformSpatialPose {

    /// Create a pose waveform from separate position and quaternion waveforms
    public static func from(
        positionWaveform: WaveformPosition<T>,
        quaternionWaveform: WaveformQuaternion<T>
    ) -> WaveformSpatialPose<T>? {
        // Check sample counts match
        guard positionWaveform.values.count == quaternionWaveform.values.count else {
            return nil
        }

        // Compare dt (PrecisionTimeInterval has exact equality) and t0
        guard positionWaveform.dt == quaternionWaveform.dt && positionWaveform.t0 == quaternionWaveform.t0 else {
            return nil
        }

        return WaveformSpatialPose<T>(
            positions: positionWaveform.values,
            quaternions: quaternionWaveform.values,
            dt: positionWaveform.dt,
            t0: positionWaveform.t0
        )
    }
}

// MARK: - Equatable
extension WaveformSpatialPose: Equatable {
    public static func == (lhs: WaveformSpatialPose<T>, rhs: WaveformSpatialPose<T>) -> Bool {
        // Compare dt first (PrecisionTimeInterval has exact equality)
        guard lhs.dt == rhs.dt else { return false }

        // Compare t0
        guard lhs.t0 == rhs.t0 else { return false }

        // Compare positions and quaternions arrays
        guard lhs.positions == rhs.positions && lhs.quaternions == rhs.quaternions else { return false }

        return true
    }
}

// MARK: - Hashable
extension WaveformSpatialPose: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(positions)
        hasher.combine(quaternions)
        hasher.combine(dt)
        hasher.combine(t0)
    }
}

// MARK: - CustomStringConvertible
extension WaveformSpatialPose: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "WaveformSpatialPose(samples: \(sampleCount), dt: \(dt), duration: \(duration))"
    }

    public var debugDescription: String {
        return
            "WaveformSpatialPose<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration))"
    }
}
