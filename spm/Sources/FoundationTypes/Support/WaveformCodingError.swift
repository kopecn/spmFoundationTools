import Foundation

/// Unified coding error for all waveform types
public enum WaveformCodingError: Error, LocalizedError {
    case stringConversionFailed
    case invalidFileFormat
    case missingRequiredField(String)
    case incompatibleComponentWaveforms
    case emptyCSVFile
    case invalidCSVFormat(expected: String)
    case insufficientData

    public var errorDescription: String? {
        switch self {
        case .stringConversionFailed:
            return "Failed to convert JSON data to string"
        case .invalidFileFormat:
            return "Invalid file format for waveform data"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .incompatibleComponentWaveforms:
            return "Component waveforms have incompatible dimensions or sampling rates"
        case .emptyCSVFile:
            return "CSV file is empty"
        case .invalidCSVFormat(let expected):
            return "CSV file has invalid format - expected \(expected) columns"
        case .insufficientData:
            return "Insufficient data points in CSV file"
        }
    }
}
