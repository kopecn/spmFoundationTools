import Foundation

/// Frequency offset or systematic drift calibration status
///
/// Represents a deterministic deviation of an oscillator's frequency from its nominal value.
/// This error accumulates **linearly over time** and is typically caused by:
/// - Manufacturing tolerances in crystal oscillators
/// - Aging effects in the oscillator
/// - Systematic bias in the clock source
///
/// The associated UInt64 value represents the **6-sigma (6σ) uncertainty** in attoseconds.
/// This provides a 99.7% confidence interval for the frequency offset error.
///
/// ## Calibration States
/// - **precalibrated**: The waveform has NOT been corrected for this error source.
///   The value represents the known/measured systematic drift.
/// - **calibrated**: The waveform HAS been corrected for this error source.
///   The value represents the residual uncertainty after calibration.
///
/// ## Example
/// ```swift
/// // Uncalibrated clock with 1 microsecond systematic drift
/// let offset = FrequencyOffset.precalibrated(1_000_000_000_000) // 1μs in attoseconds
///
/// // After calibration, residual uncertainty is 10 nanoseconds
/// let calibrated = offset.flippedCalibrationStatus()
/// ```
public enum FrequencyOffset: Sendable, Hashable, Codable {
    /// Waveform has not been calibrated for this error source
    /// - Parameter UInt64: 6-sigma uncertainty in attoseconds
    case precalibrated(UInt64)

    /// Waveform has been calibrated for this error source
    /// - Parameter UInt64: 6-sigma residual uncertainty in attoseconds
    case calibrated(UInt64)

    /// Returns the 6-sigma uncertainty value in attoseconds
    public var uncertainty: UInt64 {
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

    /// Flips the calibration status while maintaining the uncertainty value
    ///
    /// Converts between precalibrated and calibrated states without changing
    /// the associated 6-sigma uncertainty value.
    ///
    /// - Returns: A new FrequencyOffset with flipped calibration status
    ///
    /// Example:
    /// ```swift
    /// let precal = FrequencyOffset.precalibrated(1000)
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
