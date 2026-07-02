import Foundation

/// Phase noise or short-term jitter calibration status
///
/// Represents fast, random fluctuations in a clock's phase or edge timing.
/// This manifests as **high-frequency deviations** around the ideal clock edge and is typically caused by:
/// - Thermal noise in oscillator circuits
/// - Power supply voltage fluctuations
/// - Electromagnetic interference (EMI)
/// - Shot noise in electronic components
///
/// The associated UInt64 value represents the **6-sigma (6σ) RMS jitter** in attoseconds.
/// This provides a 99.7% confidence interval for the phase jitter magnitude.
///
/// ## Calibration States
/// - **precalibrated**: The waveform has NOT been corrected for this error source.
///   The value represents the measured peak-to-peak or RMS jitter.
/// - **calibrated**: The waveform HAS been corrected/filtered for this error source.
///   The value represents the residual jitter after filtering.
///
/// ## Example
/// ```swift
/// // High-frequency jitter of 100 picoseconds RMS
/// let jitter = PhaseJitter.precalibrated(100_000_000) // 100ps in attoseconds
///
/// // After digital filtering, residual jitter is 10 picoseconds
/// let filtered = PhaseJitter.calibrated(10_000_000)
/// ```
public enum PhaseJitter: Sendable, Hashable, Codable {
    /// Waveform has not been calibrated for this error source
    /// - Parameter UInt64: 6-sigma RMS jitter in attoseconds
    case precalibrated(UInt64)

    /// Waveform has been calibrated for this error source
    /// - Parameter UInt64: 6-sigma residual jitter in attoseconds
    case calibrated(UInt64)

    /// Returns the 6-sigma RMS jitter value in attoseconds
    public var jitter: UInt64 {
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

    /// Flips the calibration status while maintaining the jitter value
    ///
    /// Converts between precalibrated and calibrated states without changing
    /// the associated 6-sigma RMS jitter value.
    ///
    /// - Returns: A new PhaseJitter with flipped calibration status
    ///
    /// Example:
    /// ```swift
    /// let precal = PhaseJitter.precalibrated(1000)
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
