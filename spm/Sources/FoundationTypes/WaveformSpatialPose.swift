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
/// let startTime = Date()
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

    /// The time interval between consecutive samples in seconds
    public var dt: TimeInterval

    /// The absolute start time of the first sample
    public var t0: Date?

    /// Initialize a pose waveform
    /// - Parameters:
    ///   - positions: The sampled position values
    ///   - quaternions: The sampled quaternion values
    ///   - dt: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    /// - Note: If positions and quaternions have different counts, `isValid` will be false and `sampleCount` will return the minimum
    public init(positions: [Position<T>], quaternions: [Quaternion<T>], dt: TimeInterval, t0: Date?) {
        precondition(dt > 0, "Time interval (dt) must be positive, got \(dt)")
        self.positions = positions
        self.quaternions = quaternions
        self.dt = dt
        self.t0 = t0
    }

    /// Initialize with positions and quaternions only, using default dt=1.0 and t0=nil
    public init(positions: [Position<T>], quaternions: [Quaternion<T>]) {
        self.init(positions: positions, quaternions: quaternions, dt: 1.0, t0: nil)
    }

    /// Initialize with positions, quaternions and dt, using default t0=nil
    public init(positions: [Position<T>], quaternions: [Quaternion<T>], dt: TimeInterval) {
        self.init(positions: positions, quaternions: quaternions, dt: dt, t0: nil)
    }

    /// Initialize from an array of SpatialPose instances
    /// - Parameters:
    ///   - poses: Array of SpatialPose instances to convert to waveform
    ///   - dt: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    public init(poses: [SpatialPose<T>], dt: TimeInterval, t0: Date?) {
        precondition(dt > 0, "Time interval (dt) must be positive, got \(dt)")
        self.positions = poses.map { $0.position }
        self.quaternions = poses.map { $0.quaternion }
        self.dt = dt
        self.t0 = t0
    }

    /// Initialize from an array of SpatialPose instances with default dt=1.0 and t0=nil
    /// - Parameter poses: Array of SpatialPose instances to convert to waveform
    public init(poses: [SpatialPose<T>]) {
        self.init(poses: poses, dt: 1.0, t0: nil)
    }

    /// Initialize from an array of SpatialPose instances with dt, using default t0=nil
    /// - Parameters:
    ///   - poses: Array of SpatialPose instances to convert to waveform
    ///   - dt: The time interval between samples in seconds (must be positive)
    public init(poses: [SpatialPose<T>], dt: TimeInterval) {
        self.init(poses: poses, dt: dt, t0: nil)
    }

    // MARK: - Computed Properties (Available to all pose types)

    /// Get the total duration of the waveform
    public var duration: TimeInterval {
        guard sampleCount > 1 else { return 0 }
        return TimeInterval(sampleCount - 1) * dt
    }

    /// Get the sampling frequency (Hz)
    public var samplingFrequency: Double {
        return 1.0 / dt
    }

    /// Get the Nyquist frequency (Hz)
    public var nyquistFrequency: Double {
        return samplingFrequency / 2.0
    }

    /// Get the end time of the waveform
    public var endTime: Date? {
        guard let t0 = t0 else { return nil }
        return t0.addingTimeInterval(duration)
    }

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
        return WaveformSpatialPose<T>(positions: normalizedPositions, quaternions: normalizedQuaternions, dt: dt, t0: t0)
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
        return WaveformSpatialPose<T>(positions: normalizedPositions, quaternions: normalizedQuaternions, dt: dt, t0: t0)
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

        // Compare dt with relative tolerance
        let dtEqual: Bool
        if positionWaveform.dt == 0 && quaternionWaveform.dt == 0 {
            dtEqual = true
        } else if positionWaveform.dt == 0 || quaternionWaveform.dt == 0 {
            dtEqual = abs(positionWaveform.dt - quaternionWaveform.dt) < 1e-10
        } else {
            let relativeDifference =
                abs(positionWaveform.dt - quaternionWaveform.dt)
                / max(abs(positionWaveform.dt), abs(quaternionWaveform.dt))
            dtEqual = relativeDifference < 1e-10
        }

        guard dtEqual && positionWaveform.t0 == quaternionWaveform.t0 else {
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
        // Compare positions and quaternions arrays
        guard lhs.positions == rhs.positions && lhs.quaternions == rhs.quaternions else { return false }

        // Compare dt with appropriate tolerance for TimeInterval (Double)
        // Use relative tolerance for better handling of different magnitudes
        let dtEqual: Bool
        if lhs.dt == 0 && rhs.dt == 0 {
            dtEqual = true
        } else if lhs.dt == 0 || rhs.dt == 0 {
            dtEqual = abs(lhs.dt - rhs.dt) < 1e-10
        } else {
            let relativeDifference = abs(lhs.dt - rhs.dt) / max(abs(lhs.dt), abs(rhs.dt))
            dtEqual = relativeDifference < 1e-10
        }

        // Compare t0
        guard lhs.t0 == rhs.t0 else { return false }

        return dtEqual
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
        return "WaveformSpatialPose(samples: \(sampleCount), dt: \(dt), duration: \(duration)s)"
    }

    public var debugDescription: String {
        return
            "WaveformSpatialPose<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration)s)"
    }
}
