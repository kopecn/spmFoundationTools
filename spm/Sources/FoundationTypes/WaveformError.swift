import Foundation

/// Unified error types for all waveform operations
public enum WaveformError: Error, LocalizedError {
    case incompatibleSamplingRates
    case incompatibleDimensions
    case invalidTimeRange

    public var errorDescription: String? {
        switch self {
        case .incompatibleSamplingRates:
            return "Waveforms have incompatible sampling rates"
        case .incompatibleDimensions:
            return "Waveforms have incompatible dimensions"
        case .invalidTimeRange:
            return "Invalid time range specified"
        }
    }
}
