import Foundation

/// Long-term wander or random walk calibration status
///
/// Represents slow, stochastic variations in a clock's phase over extended periods.
/// Unlike systematic drift (which grows linearly), wander grows roughly as **√t** (square root of time)
/// due to its random walk nature. This is typically caused by:
/// - Flicker noise (1/f noise) in oscillators
/// - Slow environmental variations (temperature, humidity, pressure)
/// - Brownian motion in mechanical resonators (MEMS oscillators)
/// - Aging effects with random components
///
/// The associated UInt64 value represents the **6-sigma (6σ) Allan deviation** in attoseconds.
/// This provides a 99.7% confidence interval for the wander magnitude at a specific averaging time.
///
/// ## Calibration States
/// - **precalibrated**: The waveform has NOT been corrected for this error source.
///   The value represents the measured Allan deviation or random walk coefficient.
/// - **calibrated**: The waveform HAS been corrected using statistical filtering.
///   The value represents the residual wander after correction.
///
/// ## Example
/// ```swift
/// // Long-term wander with Allan deviation of 1 nanosecond
/// let wander = Wander.precalibrated(1_000_000_000) // 1ns in attoseconds
///
/// // After Kalman filtering, residual wander is 100 picoseconds
/// let filtered = Wander.calibrated(100_000_000)
/// ```
///
/// ## Reference
/// For more information on Allan deviation and clock stability metrics, see:
/// - IEEE 1139-2008: Standard Definitions of Physical Quantities for Fundamental Frequency and Time Metrology
public enum Wander: Sendable, Hashable, Codable {
    /// Waveform has not been calibrated for this error source
    /// - Parameter UInt64: 6-sigma Allan deviation in attoseconds
    case precalibrated(UInt64)

    /// Waveform has been calibrated for this error source
    /// - Parameter UInt64: 6-sigma residual Allan deviation in attoseconds
    case calibrated(UInt64)

    /// Returns the 6-sigma Allan deviation value in attoseconds
    public var allanDeviation: UInt64 {
        switch self {
        case .precalibrated(let value), .calibrated(let value):
            return value
        }
    }

    /// Returns true if the waveform has been calibrated for this error source
    public var isCalibrated: Bool {
        switch self {
        case .calibrated:
            return true
        case .precalibrated:
            return false
        }
    }

    /// Flips the calibration status while maintaining the Allan deviation value
    ///
    /// Converts between precalibrated and calibrated states without changing
    /// the associated 6-sigma Allan deviation value.
    ///
    /// - Returns: A new Wander with flipped calibration status
    ///
    /// Example:
    /// ```swift
    /// let precal = Wander.precalibrated(1000)
    /// let cal = precal.flippedCalibrationStatus() // .calibrated(1000)
    /// let backToPrecal = cal.flippedCalibrationStatus() // .precalibrated(1000)
    /// ```
    public func flippedCalibrationStatus() -> Self {
        switch self {
        case .precalibrated(let value):
            return .calibrated(value)
        case .calibrated(let value):
            return .precalibrated(value)
        }
    }
}
