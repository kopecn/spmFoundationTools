import Foundation

/// Temperature or environmental drift calibration status
///
/// Represents systematic frequency and phase changes caused by environmental factors,
/// primarily temperature variations. Unlike other error sources, this drift is:
/// - **Deterministic** (given the environmental conditions)
/// - **Reversible** (frequency returns to nominal when temperature stabilizes)
/// - **Calibratable** (via lookup tables or compensation functions)
///
/// ## Common Environmental Factors
/// - **Temperature**: Primary driver of frequency drift in most oscillators
///   - Crystal oscillators: ~0.035 ppm/°C (AT-cut quartz)
///   - MEMS oscillators: ~0.5 to 5 ppm/°C
/// - **Voltage**: Power supply variations affect oscillator frequency
/// - **Pressure**: Affects sealed oscillators (less common)
/// - **Humidity**: Can affect unsealed or poorly packaged oscillators
///
/// ## Why No Associated Value?
/// Unlike other calibration states, `TemperatureDrift` does NOT store a single uncertainty value
/// because the drift magnitude depends on the **instantaneous environmental conditions**.
/// Proper temperature compensation requires:
/// 1. An external temperature waveform (synchronized with the time waveform)
/// 2. A calibration lookup table or polynomial function
/// 3. Real-time correlation between temperature and frequency offset
///
/// ## Calibration States
/// - **precalibrated**: The waveform has NOT been corrected for environmental drift.
///   External temperature data should be correlated to apply corrections.
/// - **calibrated**: The waveform HAS been corrected using temperature compensation.
///   A temperature-to-frequency lookup table or TCXO compensation was applied.
///
/// ## Example
/// ```swift
/// // Mark that temperature compensation is needed
/// let drift = TemperatureDrift.precalibrated
///
/// // After applying TCXO compensation or lookup table
/// let compensated = drift.flippedCalibrationStatus() // .calibrated
/// ```
///
/// ## Typical Compensation Methods
/// - **TCXO (Temperature Compensated Crystal Oscillator)**: Hardware compensation
/// - **Polynomial correction**: Software-based T² or T³ polynomial fits
/// - **Lookup table**: Measured frequency offset at discrete temperatures
/// - **Kalman filtering**: Combined with temperature sensor data
public enum TemperatureDrift: Sendable, Hashable, Codable {
    /// Waveform has not been calibrated for temperature drift
    ///
    /// External temperature waveform correlation is required to estimate
    /// and correct for temperature-induced frequency variations.
    case precalibrated

    /// Waveform has been calibrated for temperature drift
    ///
    /// Temperature compensation (TCXO, lookup table, or polynomial) has been
    /// applied to correct for environmental frequency variations.
    case calibrated

    /// Returns true if the waveform has been calibrated for temperature drift
    public var isCalibrated: Bool {
        switch self {
        case .calibrated:
            return true
        case .precalibrated:
            return false
        }
    }

    /// Flips the calibration status
    ///
    /// Converts between precalibrated and calibrated states to indicate
    /// whether temperature compensation has been applied.
    ///
    /// - Returns: A new TemperatureDrift with flipped calibration status
    ///
    /// Example:
    /// ```swift
    /// let precal = TemperatureDrift.precalibrated
    /// let cal = precal.flippedCalibrationStatus() // .calibrated
    /// let backToPrecal = cal.flippedCalibrationStatus() // .precalibrated
    /// ```
    public func flippedCalibrationStatus() -> Self {
        switch self {
        case .precalibrated:
            return .calibrated
        case .calibrated:
            return .precalibrated
        }
    }
}
