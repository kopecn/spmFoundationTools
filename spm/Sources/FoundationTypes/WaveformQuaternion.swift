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
/// let startTime = PrecisionTimestamp()
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
public struct WaveformQuaternion<T: BinaryFloatingPoint & SIMDScalar & Sendable>: Sendable
where T.SIMD4Storage: Sendable {
    /// The sampled quaternion values of the waveform
    public var values: [Quaternion<T>]

    /// The time interval between consecutive samples
    public var dt: PrecisionTimeInterval

    /// The absolute start time of the first sample
    public var t0: PrecisionTimestamp?

    /// Initialize a quaternion waveform
    /// - Parameters:
    ///   - values: The sampled quaternion values
    ///   - dt: The time interval between samples (must be positive, defaults to 1 second)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    public init(
        values: [Quaternion<T>],
        dt: PrecisionTimeInterval = PrecisionTimeInterval(seconds: 1.0),
        t0: PrecisionTimestamp? = nil
    ) {
        precondition(dt > .zero, "Time interval (dt) must be positive, got \(dt)")
        self.values = values
        self.dt = dt
        self.t0 = t0
    }

    /// Convenience initializer with dt in seconds as Double
    /// - Parameters:
    ///   - values: The sampled quaternion values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(values: [Quaternion<T>], dtSeconds: Double, t0: PrecisionTimestamp? = nil) {
        self.init(values: values, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    /// Convenience initializer with dt in seconds as Float
    /// - Parameters:
    ///   - values: The sampled quaternion values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(values: [Quaternion<T>], dtSeconds: Float, t0: PrecisionTimestamp? = nil) {
        self.init(values: values, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    // MARK: - Computed Properties (Available to all quaternion types)

    /// Get the total duration of the waveform as a PrecisionTimeInterval
    public var duration: PrecisionTimeInterval {
        guard values.count > 1 else { return .zero }
        return dt * (values.count - 1)
    }

    /// Get the total duration of the waveform in seconds as the specified floating point type
    public func durationInSeconds<U: BinaryFloatingPoint>() -> U {
        guard values.count > 1 else { return 0 }
        return U(Double(values.count - 1) * dt.secondsAsDouble)
    }

    /// Get the sampling frequency (Hz) in the specified floating point type
    public func samplingFrequencyInHz<U: BinaryFloatingPoint>() -> U {
        return U(1.0 / dt.secondsAsDouble)
    }

    /// Get the Nyquist frequency (Hz) in the specified floating point type
    public func nyquistFrequencyInHz<U: BinaryFloatingPoint>() -> U {
        return samplingFrequencyInHz() / 2.0
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
        guard x.values.count == y.values.count && y.values.count == z.values.count && z.values.count == w.values.count
        else {
            return nil
        }

        // Compare dt values (PrecisionTimeInterval has exact equality)
        guard x.dt == y.dt && y.dt == z.dt && z.dt == w.dt else {
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
}

// MARK: - Equatable
extension WaveformQuaternion: Equatable {
    public static func == (lhs: WaveformQuaternion<T>, rhs: WaveformQuaternion<T>) -> Bool {
        // Compare dt first (PrecisionTimeInterval has exact equality)
        guard lhs.dt == rhs.dt else { return false }

        // Compare t0
        guard lhs.t0 == rhs.t0 else { return false }

        // Compare values array
        guard lhs.values == rhs.values else { return false }

        return true
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
        let durationStr = duration.description
        let durationWithUnit = durationStr.hasSuffix("s") ? durationStr : "\(durationStr)s"
        return "WaveformQuaternion(samples: \(sampleCount), dt: \(dt), duration: \(durationWithUnit))"
    }

    public var debugDescription: String {
        let durationStr = duration.description
        let durationWithUnit = durationStr.hasSuffix("s") ? durationStr : "\(durationStr)s"
        return
            "WaveformQuaternion<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(durationWithUnit))"
    }
}
