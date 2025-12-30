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
/// let startTime = PrecisionTimestamp()
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

    /// The time interval between consecutive samples
    public var dt: PrecisionTimeInterval

    /// The absolute start time of the first sample
    public var t0: PrecisionTimestamp?

    /// Initialize a position waveform
    /// - Parameters:
    ///   - values: The sampled position values
    ///   - dt: The time interval between samples (must be positive, defaults to 1 second)
    ///   - t0: The absolute start time of the first sample
    /// - Precondition: dt must be greater than 0
    public init(values: [Position<T>], dt: PrecisionTimeInterval = PrecisionTimeInterval(seconds: 1.0), t0: PrecisionTimestamp? = nil) {
        precondition(dt > .zero, "Time interval (dt) must be positive, got \(dt)")
        self.values = values
        self.dt = dt
        self.t0 = t0
    }

    /// Convenience initializer with dt in seconds as Double
    /// - Parameters:
    ///   - values: The sampled position values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(values: [Position<T>], dtSeconds: Double, t0: PrecisionTimestamp? = nil) {
        self.init(values: values, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    /// Convenience initializer with dt in seconds as Float
    /// - Parameters:
    ///   - values: The sampled position values
    ///   - dtSeconds: The time interval between samples in seconds (must be positive)
    ///   - t0: The absolute start time of the first sample (optional)
    public init(values: [Position<T>], dtSeconds: Float, t0: PrecisionTimestamp? = nil) {
        self.init(values: values, dt: PrecisionTimeInterval(seconds: dtSeconds), t0: t0)
    }

    // MARK: - Computed Properties (Available to all position types)

    /// Get the total duration of the waveform as a PrecisionTimeInterval
    public var duration: PrecisionTimeInterval {
        guard values.count > 1 else { return .zero }
        return dt * values.count
    }

    // FIXME: -- 
    // /// Get the total duration of the waveform in seconds as the specified floating point type
    // public func durationInSeconds<U: BinaryFloatingPoint>() -> U {
    //     guard values.count > 1 else { return 0 }
    //     let dtSeconds: U = dt.asFloatingPoint()
    //     return U(values.count - 1) * dtSeconds
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
        // Check sample counts match
        guard x.values.count == y.values.count && y.values.count == z.values.count else {
            return nil
        }

        // Compare dt values (PrecisionTimeInterval has exact equality)
        guard x.dt == y.dt && y.dt == z.dt else {
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
}

// MARK: - Equatable
extension WaveformPosition: Equatable {
    public static func == (lhs: WaveformPosition<T>, rhs: WaveformPosition<T>) -> Bool {
        // Compare values array
        guard lhs.values == rhs.values else { return false }

        // Compare dt (PrecisionTimeInterval has exact equality)
        guard lhs.dt == rhs.dt else { return false }

        // Compare t0
        guard lhs.t0 == rhs.t0 else { return false }

        return true
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
        return "WaveformPosition(samples: \(sampleCount), dt: \(dt), duration: \(duration))"
    }

    public var debugDescription: String {
        return
            "WaveformPosition<\(T.self)>(samples: \(sampleCount), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration))"
    }
}
