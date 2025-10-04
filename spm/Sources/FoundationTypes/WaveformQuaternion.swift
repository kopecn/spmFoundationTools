import Foundation
import simd

// Convenience typealiases for common use cases
public typealias DoubleWaveformQuaternion = WaveformQuaternion<Double>
public typealias FloatWaveformQuaternion = WaveformQuaternion<Float>

/// A quaternion waveform data structure representing time-series orientation data.
///
/// `WaveformQuaternion` stores uniformly sampled quaternion values with their temporal characteristics,
/// making it suitable for motion tracking, orientation analysis, and rotational time-series data.
///
/// Example usage:
/// ```swift
/// let startTime = Date()
/// let samplingInterval = 0.001 // 1ms sampling
/// let quaternions: [FloatQuaternion] = [
///     FloatQuaternion.identity,
///     FloatQuaternion(x: 0.1, y: 0.0, z: 0.0, w: 0.995),
///     FloatQuaternion(x: 0.2, y: 0.0, z: 0.0, w: 0.98)
/// ]
/// var waveform = WaveformQuaternion(values: quaternions, dt: samplingInterval, t0: startTime)
///
/// // Double quaternion waveform
/// var doubleWaveform = DoubleWaveformQuaternion(values: [DoubleQuaternion.identity])
/// ```
public struct WaveformQuaternion<T: BinaryFloatingPoint & SIMDScalar & Sendable>: Sendable {
    /// The sampled quaternion values of the waveform
    public var values: [Quaternion<T>]

    /// The time interval between consecutive samples in seconds
    public var dt: TimeInterval

    /// The absolute start time of the first sample
    public var t0: Date?

    /// Initialize a quaternion waveform
    /// - Parameters:
    ///   - values: The sampled quaternion values
    ///   - dt: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    public init(values: [Quaternion<T>], dt: TimeInterval, t0: Date?) {
        precondition(dt > 0, "Time interval (dt) must be positive, got \(dt)")
        self.values = values
        self.dt = dt
        self.t0 = t0
    }

    /// Initialize with values only, using default dt=1.0 and t0=nil
    public init(values: [Quaternion<T>]) {
        self.init(values: values, dt: 1.0, t0: nil)
    }

    /// Initialize with values and dt, using default t0=nil
    public init(values: [Quaternion<T>], dt: TimeInterval) {
        self.init(values: values, dt: dt, t0: nil)
    }

    // MARK: - Computed Properties (Available to all quaternion types)

    /// Get the total duration of the waveform
    public var duration: TimeInterval {
        guard values.count > 1 else { return 0 }
        return TimeInterval(values.count - 1) * dt
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

    /// Get the number of samples
    public var sampleCount: Int {
        return values.count
    }
}

// MARK: - Computed Properties for Float Types
extension WaveformQuaternion where T == Float {

    /// Check if all quaternions in the waveform are normalized (unit quaternions)
    public var areAllNormalized: Bool {
        return values.allSatisfy { $0.isUnit }
    }

    /// Normalize all quaternions in the waveform using Quaternion's normalize method
    public mutating func normalize() {
        for i in 0..<values.count {
            values[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform using Quaternion's normalized property
    public var normalized: WaveformQuaternion<T> {
        let normalizedValues = values.map { $0.normalized }
        return WaveformQuaternion<T>(values: normalizedValues, dt: dt, t0: t0)
    }

    /// Extract component waveforms (x, y, z, w)
    public var componentWaveforms: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>, w: Waveform1D<T>) {
        let xValues = values.map { $0.x }
        let yValues = values.map { $0.y }
        let zValues = values.map { $0.z }
        let wValues = values.map { $0.w }

        return (
            x: Waveform1D<T>(values: xValues, dt: dt, t0: t0),
            y: Waveform1D<T>(values: yValues, dt: dt, t0: t0),
            z: Waveform1D<T>(values: zValues, dt: dt, t0: t0),
            w: Waveform1D<T>(values: wValues, dt: dt, t0: t0)
        )
    }
}

// MARK: - Computed Properties for Double Types
extension WaveformQuaternion where T == Double {

    /// Check if all quaternions in the waveform are normalized (unit quaternions)
    public var areAllNormalized: Bool {
        return values.allSatisfy { $0.isUnit }
    }

    /// Normalize all quaternions in the waveform using Quaternion's normalize method
    public mutating func normalize() {
        for i in 0..<values.count {
            values[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform using Quaternion's normalized property
    public var normalized: WaveformQuaternion<T> {
        let normalizedValues = values.map { $0.normalized }
        return WaveformQuaternion<T>(values: normalizedValues, dt: dt, t0: t0)
    }

    /// Extract component waveforms (x, y, z, w)
    public var componentWaveforms: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>, w: Waveform1D<T>) {
        let xValues = values.map { $0.x }
        let yValues = values.map { $0.y }
        let zValues = values.map { $0.z }
        let wValues = values.map { $0.w }

        return (
            x: Waveform1D<T>(values: xValues, dt: dt, t0: t0),
            y: Waveform1D<T>(values: yValues, dt: dt, t0: t0),
            z: Waveform1D<T>(values: zValues, dt: dt, t0: t0),
            w: Waveform1D<T>(values: wValues, dt: dt, t0: t0)
        )
    }
}

// MARK: - Utility Methods
extension WaveformQuaternion {

    /// Create a waveform from component waveforms
    public static func from(
        x: Waveform1D<T>,
        y: Waveform1D<T>,
        z: Waveform1D<T>,
        w: Waveform1D<T>
    ) -> WaveformQuaternion<T>? {
        // Check sample counts match
        guard x.values.count == y.values.count && y.values.count == z.values.count && z.values.count == w.values.count else {
            return nil
        }

        // Compare dt values with relative tolerance
        let dtEqual: Bool
        if x.dt == 0 && y.dt == 0 && z.dt == 0 && w.dt == 0 {
            dtEqual = true
        } else {
            let maxDt = max(x.dt, y.dt, z.dt, w.dt)
            let relativeDiffXY = abs(x.dt - y.dt) / maxDt
            let relativeDiffYZ = abs(y.dt - z.dt) / maxDt
            let relativeDiffZW = abs(z.dt - w.dt) / maxDt
            dtEqual = relativeDiffXY < 1e-10 && relativeDiffYZ < 1e-10 && relativeDiffZW < 1e-10
        }

        guard dtEqual else {
            return nil
        }

        // Cleaner approach using indices
        let quaternions = (0..<x.values.count).map { i in
            return Quaternion<T>(
                x: x.values[i],
                y: y.values[i],
                z: z.values[i],
                w: w.values[i]
            )
        }

        return WaveformQuaternion<T>(values: quaternions, dt: x.dt, t0: x.t0)
    }

    /// Append another quaternion waveform to this one
    /// Both waveforms must have the same sampling rate
    public mutating func append(_ other: WaveformQuaternion<T>) throws {
        // Compare dt with relative tolerance
        let dtEqual: Bool
        if self.dt == 0 && other.dt == 0 {
            dtEqual = true
        } else if self.dt == 0 || other.dt == 0 {
            dtEqual = abs(self.dt - other.dt) < 1e-10
        } else {
            let relativeDifference = abs(self.dt - other.dt) / max(abs(self.dt), abs(other.dt))
            dtEqual = relativeDifference < 1e-10
        }

        guard dtEqual else {
            throw WaveformError.incompatibleSamplingRates
        }

        self.values.append(contentsOf: other.values)
    }

    /// Create a new waveform by concatenating this one with another
    public func concatenated(with other: WaveformQuaternion<T>) throws -> WaveformQuaternion<T> {
        var result = self
        try result.append(other)
        return result
    }
}

// MARK: - Equatable
extension WaveformQuaternion: Equatable {
    public static func == (lhs: WaveformQuaternion<T>, rhs: WaveformQuaternion<T>) -> Bool {
        // Compare values array
        guard lhs.values == rhs.values else { return false }

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
extension WaveformQuaternion: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
        hasher.combine(dt)
        hasher.combine(t0)
    }
}

// MARK: - CustomStringConvertible
extension WaveformQuaternion: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "WaveformQuaternion(samples: \(sampleCount), dt: \(dt), duration: \(duration)s)"
    }

    public var debugDescription: String {
        return
            "WaveformQuaternion<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration)s)"
    }
}
