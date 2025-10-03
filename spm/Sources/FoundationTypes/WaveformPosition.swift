import Foundation
import simd

// Convenience typealiases for common use cases
public typealias DoubleWaveformPosition = WaveformPosition<Double>
public typealias FloatWaveformPosition = WaveformPosition<Float>

/// A position waveform data structure representing time-series spatial position data.
///
/// `WaveformPosition` stores uniformly sampled position values with their temporal characteristics,
/// making it suitable for motion tracking, trajectory analysis, and spatial time-series data.
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
/// var waveform = WaveformPosition(values: positions, dt: samplingInterval, t0: startTime)
///
/// // Double position waveform
/// var doubleWaveform = DoubleWaveformPosition(values: [DoublePosition.origin])
/// ```
public struct WaveformPosition<T: BinaryFloatingPoint & SIMDScalar & Sendable>: Sendable {
    /// The sampled position values of the waveform
    public var values: [Position<T>]

    /// The time interval between consecutive samples in seconds
    public var dt: TimeInterval

    /// The absolute start time of the first sample
    public var t0: Date?

    /// Initialize with all parameters
    public init(values: [Position<T>], dt: TimeInterval, t0: Date?) {
        self.values = values
        self.dt = dt
        self.t0 = t0
    }

    /// Initialize with values only, using default dt=1.0 and t0=nil
    public init(values: [Position<T>]) {
        self.init(values: values, dt: 1.0, t0: nil)
    }

    /// Initialize with values and dt, using default t0=nil
    public init(values: [Position<T>], dt: TimeInterval) {
        self.init(values: values, dt: dt, t0: nil)
    }

    // MARK: - Computed Properties (Available to all position types)

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
extension WaveformPosition where T == Float {

    /// Check if all positions in the waveform are unit positions (magnitude ≈ 1)
    public var areAllUnit: Bool {
        return values.allSatisfy { $0.isUnit }
    }

    /// Normalize all positions in the waveform using Position's normalize method
    public mutating func normalize() {
        for i in 0..<values.count {
            values[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform using Position's normalized property
    public var normalized: WaveformPosition<T> {
        let normalizedValues = values.map { $0.normalized }
        return WaveformPosition<T>(values: normalizedValues, dt: dt, t0: t0)
    }

    /// Extract component waveforms (x, y, z)
    public var componentWaveforms: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>) {
        let xValues = values.map { $0.x }
        let yValues = values.map { $0.y }
        let zValues = values.map { $0.z }

        return (
            x: Waveform1D<T>(values: xValues, dt: dt, t0: t0),
            y: Waveform1D<T>(values: yValues, dt: dt, t0: t0),
            z: Waveform1D<T>(values: zValues, dt: dt, t0: t0)
        )
    }
}

// MARK: - Computed Properties for Double Types
extension WaveformPosition where T == Double {

    /// Check if all positions in the waveform are unit positions (magnitude ≈ 1)
    public var areAllUnit: Bool {
        return values.allSatisfy { $0.isUnit }
    }

    /// Normalize all positions in the waveform using Position's normalize method
    public mutating func normalize() {
        for i in 0..<values.count {
            values[i].normalize()
        }
    }

    /// Get a normalized copy of the waveform using Position's normalized property
    public var normalized: WaveformPosition<T> {
        let normalizedValues = values.map { $0.normalized }
        return WaveformPosition<T>(values: normalizedValues, dt: dt, t0: t0)
    }

    /// Extract component waveforms (x, y, z)
    public var componentWaveforms: (x: Waveform1D<T>, y: Waveform1D<T>, z: Waveform1D<T>) {
        let xValues = values.map { $0.x }
        let yValues = values.map { $0.y }
        let zValues = values.map { $0.z }

        return (
            x: Waveform1D<T>(values: xValues, dt: dt, t0: t0),
            y: Waveform1D<T>(values: yValues, dt: dt, t0: t0),
            z: Waveform1D<T>(values: zValues, dt: dt, t0: t0)
        )
    }
}

// MARK: - Utility Methods
extension WaveformPosition {

    /// Create a waveform from component waveforms
    public static func from(
        x: Waveform1D<T>,
        y: Waveform1D<T>,
        z: Waveform1D<T>
    ) -> WaveformPosition<T>? {
        guard
            x.values.count == y.values.count && y.values.count == z.values.count
                && abs(x.dt - y.dt) < 1e-10 && abs(y.dt - z.dt) < 1e-10
        else {
            return nil
        }

        let positions = (0..<x.values.count).map { i in
            return Position<T>(
                x: x.values[i],
                y: y.values[i],
                z: z.values[i]
            )
        }

        return WaveformPosition<T>(values: positions, dt: x.dt, t0: x.t0)
    }

    /// Append another position waveform to this one
    /// Both waveforms must have the same sampling rate
    public mutating func append(_ other: WaveformPosition<T>) throws {
        guard abs(self.dt - other.dt) < 1e-10 else {
            throw WaveformError.incompatibleSamplingRates
        }

        self.values.append(contentsOf: other.values)
    }

    /// Create a new waveform by concatenating this one with another
    public func concatenated(with other: WaveformPosition<T>) throws -> WaveformPosition<T> {
        var result = self
        try result.append(other)
        return result
    }
}

// MARK: - Equatable
extension WaveformPosition: Equatable {
    public static func == (lhs: WaveformPosition<T>, rhs: WaveformPosition<T>) -> Bool {
        return lhs.values == rhs.values && abs(lhs.dt - rhs.dt) < 1e-10 && lhs.t0 == rhs.t0
    }
}

// MARK: - Hashable
extension WaveformPosition: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
        hasher.combine(dt)
        hasher.combine(t0)
    }
}

// MARK: - CustomStringConvertible
extension WaveformPosition: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "WaveformPosition(samples: \(sampleCount), dt: \(dt), duration: \(duration)s)"
    }

    public var debugDescription: String {
        return
            "WaveformPosition<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration)s)"
    }
}
