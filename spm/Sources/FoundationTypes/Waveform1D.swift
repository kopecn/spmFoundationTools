import Foundation

// Convenience typealiases for common use cases
public typealias DoubleWaveform1D = Waveform1D<Double, Double>
public typealias FloatWaveform1D = Waveform1D<Float, Float>
public typealias IntDWaveform1D = Waveform1D<Int, Double>
public typealias IntFWaveform1D = Waveform1D<Int, Float>

/// A one-dimensional waveform data structure representing time-series data.
///
/// `Waveform1D` stores uniformly sampled data points with their temporal characteristics,
/// making it suitable for signal processing, scientific measurements, and time-series analysis.
///
/// Example usage:
/// ```swift
/// let startTime = PrecisionTimestamp()
/// let samplingInterval = 0.001 // 1ms sampling
/// let samples: [Double] = [1.0, 2.0, 3.0, 4.0, 5.0]
/// var waveform = Waveform1D(values: samples, dt: samplingInterval, t0: startTime)
///
/// // Integer waveform
/// var intWaveform = Waveform1D(values: [1, 2, 3, 4, 5])
///
/// // Float waveform
/// var floatWaveform = Waveform1D<Float>(values: [1.0, 2.0, 3.0])
/// ```
public struct Waveform1D<T: Numeric & Sendable, U: BinaryFloatingPoint & Sendable>: Sendable {
    /// The sampled data values of the waveform
    public var values: [T]

    /// The time interval between consecutive samples in seconds
    public var dt: U

    /// The absolute start time of the first sample
    public var t0: PrecisionTimestamp?

    /// Initialize a waveform
    /// - Parameters:
    ///   - values: The sampled data values
    ///   - dt: The time interval between samples in seconds (must be positive, defaults to 1.0)
    ///   - t0: The absolute start time of the first sample (optional)
    /// - Precondition: dt must be greater than 0
    public init(values: [T], dt: U = 1.0, t0: PrecisionTimestamp? = nil) {
        precondition(dt > 0, "Time interval (dt) must be positive, got \(dt)")
        self.values = values
        self.dt = dt
        self.t0 = t0
    }

    // MARK: - Computed Properties

    /// Get the total duration of the waveform
    public var duration: U {
        guard values.count > 1 else { return 0 }
        return U(values.count - 1) * dt
    }

    /// Get the sampling frequency (Hz)
    public var samplingFrequency: U {
        return 1.0 / dt
    }

    /// Get the Nyquist frequency (Hz)
    public var nyquistFrequency: U {
        return samplingFrequency / 2.0
    }

    /// Get the number of samples
    public var sampleCount: Int {
        return values.count
    }
}

// MARK: - Computed Properties for Comparable Types
extension Waveform1D where T: Comparable {

    /// Calculate the peak-to-peak amplitude
    public var peakToPeak: T? {
        guard
            let min = values.min(),
            let max = values.max()
        else {
            return nil
        }
        return max - min
    }

    /// Get the minimum value
    public var minimum: T? {
        return values.min()
    }

    /// Get the maximum value
    public var maximum: T? {
        return values.max()
    }
}

// MARK: - Computed Properties for Floating Point Types
extension Waveform1D where T: BinaryFloatingPoint {

    /// Calculate the mean value
    public var mean: T {
        guard !values.isEmpty else { return T.zero }
        return values.reduce(T.zero, +) / T(values.count)
    }

    /// Calculate the root mean square (RMS) value
    public var rms: T {
        guard !values.isEmpty else { return T.zero }
        let sumSquares = values.reduce(T.zero) { $0 + $1 * $1 }
        return (sumSquares / T(values.count)).squareRoot()
    }

    /// Calculate the standard deviation
    public var standardDeviation: T {
        guard values.count > 1 else { return T.zero }
        let meanValue = mean
        let variance =
            values.reduce(T.zero) { sum, value in
                let deviation = value - meanValue
                return sum + deviation * deviation
            } / T(values.count - 1)
        return variance.squareRoot()
    }

    /// Calculate the variance
    public var variance: T {
        guard values.count > 1 else { return T.zero }
        let meanValue = mean
        return values.reduce(T.zero) { sum, value in
            let deviation = value - meanValue
            return sum + deviation * deviation
        } / T(values.count - 1)
    }
}

// MARK: - Computed Properties for Integer Types
extension Waveform1D where T: BinaryInteger {

    /// Calculate the mean value (integer division)
    public var mean: T {
        guard !values.isEmpty else { return T.zero }
        return values.reduce(T.zero, +) / T(values.count)
    }

    /// Calculate the sum of all values
    public var sum: T {
        return values.reduce(T.zero, +)
    }
}

// MARK: - Computed Properties for Signed Integer Types
extension Waveform1D where T: SignedInteger {

    /// Calculate the absolute sum of all values
    public var absoluteSum: T {
        return values.reduce(T.zero) { $0 + abs($1) }
    }
}

// MARK: - Equatable
extension Waveform1D: Equatable {
    public static func == (lhs: Waveform1D<T, U>, rhs: Waveform1D<T, U>) -> Bool {
        // Compare values array
        guard lhs.values == rhs.values else { return false }

        // Compare dt
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
extension Waveform1D: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
        hasher.combine(dt)
        hasher.combine(t0)
    }
}

// MARK: - CustomStringConvertible
extension Waveform1D: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Waveform1D(samples: \(values.count), dt: \(dt), duration: \(duration)s)"
    }

    public var debugDescription: String {
        return
            "Waveform1D<\(T.self)>(samples: \(values.count), dt: \(dt), t0: \(t0?.description ?? "nil"), duration: \(duration)s)"
    }
}
