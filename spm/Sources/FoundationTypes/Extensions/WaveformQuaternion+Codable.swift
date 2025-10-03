import Foundation

// MARK: - Codable Support
extension WaveformQuaternion: Codable {

    private enum CodingKeys: String, CodingKey {
        case values
        case dt
        case t0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        values = try container.decode([Quaternion<T>].self, forKey: .values)
        dt = try container.decode(TimeInterval.self, forKey: .dt)
        t0 = try container.decodeIfPresent(Date.self, forKey: .t0)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(values, forKey: .values)
        try container.encode(dt, forKey: .dt)
        try container.encodeIfPresent(t0, forKey: .t0)
    }
}

// MARK: - File Loading/Saving
extension WaveformQuaternion {

    /// Load a WaveformQuaternion from a JSON file at the specified URL
    /// - Parameter url: The URL of the JSON file to load
    /// - Returns: A decoded WaveformQuaternion instance
    /// - Throws: Decoding errors or file reading errors
    public static func load(from url: URL) throws -> WaveformQuaternion<T> {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        // Use milliseconds since 1970 for better precision
        decoder.dateDecodingStrategy = .millisecondsSince1970

        return try decoder.decode(WaveformQuaternion<T>.self, from: data)
    }

    /// Save the WaveformQuaternion to a JSON file at the specified URL
    /// - Parameter url: The URL where the JSON file should be saved
    /// - Throws: Encoding errors or file writing errors
    public func save(to url: URL) throws {
        let encoder = JSONEncoder()

        // Configure encoder for pretty printing and milliseconds since 1970 for precision
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .millisecondsSince1970

        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    /// Create a WaveformQuaternion from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded WaveformQuaternion instance
    /// - Throws: Decoding errors
    public static func from(jsonData data: Data) throws -> WaveformQuaternion<T> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(WaveformQuaternion<T>.self, from: data)
    }

    /// Convert the WaveformQuaternion to JSON data
    /// - Returns: JSON data representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return try encoder.encode(self)
    }

    /// Convert the WaveformQuaternion to a JSON string
    /// - Returns: JSON string representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw WaveformQuaternionCodingError.stringConversionFailed
        }
        return string
    }
}

// MARK: - Quaternion-Specific File Operations
extension WaveformQuaternion {

    /// Export to CSV format with quaternion components as columns
    /// - Parameter url: The URL where the CSV file should be saved
    /// - Throws: File writing errors
    public func exportToCSV(to url: URL) throws {
        var csvContent = "timestamp,x,y,z,w\n"

        for (index, quaternion) in values.enumerated() {
            let time = (t0?.timeIntervalSince1970 ?? 0) + Double(index) * dt
            csvContent += "\(time),\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)\n"
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Add this extension to constrain the CSV import to types that can be parsed from strings:

extension WaveformQuaternion where T: LosslessStringConvertible {
    /// Import from CSV format
    /// - Parameters:
    ///   - url: The URL of the CSV file to load
    ///   - hasHeader: Whether the CSV file has a header row (default: true)
    /// - Returns: A WaveformQuaternion created from the CSV data
    /// - Throws: File reading errors or parsing errors
    public static func importFromCSV(
        from url: URL,
        hasHeader: Bool = true
    ) throws -> WaveformQuaternion<T> {
        let csvContent = try String(contentsOf: url)
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw WaveformQuaternionCodingError.emptyCSVFile
        }

        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines
        var quaternions: [Quaternion<T>] = []
        var timestamps: [Double] = []

        for line in dataLines {
            let components = line.components(separatedBy: ",")
            guard components.count >= 5 else {
                throw WaveformQuaternionCodingError.invalidCSVFormat
            }

            guard let timestamp = Double(components[0]) else {
                throw WaveformQuaternionCodingError.invalidCSVFormat
            }
            
            // Parse T values using LosslessStringConvertible
            guard let x = T(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let y = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let z = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                  let w = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw WaveformQuaternionCodingError.invalidCSVFormat
            }

            timestamps.append(timestamp)
            quaternions.append(Quaternion<T>(x: x, y: y, z: z, w: w))
        }

        guard let firstTimestamp = timestamps.first,
              timestamps.count > 1 else {
            throw WaveformQuaternionCodingError.insufficientData
        }

        // Calculate dt from the difference between first two timestamps
        let dt = timestamps.count > 1 ? timestamps[1] - timestamps[0] : 1.0
        let t0 = Date(timeIntervalSince1970: firstTimestamp)

        return WaveformQuaternion<T>(values: quaternions, dt: dt, t0: t0)
    }
}

// MARK: - Coding Errors
public enum WaveformQuaternionCodingError: Error, LocalizedError {
    case stringConversionFailed
    case invalidFileFormat
    case missingRequiredField(String)
    case incompatibleComponentWaveforms
    case emptyCSVFile
    case invalidCSVFormat
    case insufficientData

    public var errorDescription: String? {
        switch self {
        case .stringConversionFailed:
            return "Failed to convert JSON data to string"
        case .invalidFileFormat:
            return "Invalid file format for quaternion waveform data"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .incompatibleComponentWaveforms:
            return "Component waveforms have incompatible dimensions or sampling rates"
        case .emptyCSVFile:
            return "CSV file is empty"
        case .invalidCSVFormat:
            return "CSV file has invalid format - expected timestamp,x,y,z,w columns"
        case .insufficientData:
            return "Insufficient data points in CSV file"
        }
    }
}

// MARK: - Convenience Extensions for Common Types
extension DoubleWaveformQuaternion {
    /// Load a DoubleWaveformQuaternion from a JSON file
    public static func loadFromFile(_ url: URL) throws -> DoubleWaveformQuaternion {
        return try load(from: url)
    }

    /// Load from CSV file with Double precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> DoubleWaveformQuaternion {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}

extension FloatWaveformQuaternion {
    /// Load a FloatWaveformQuaternion from a JSON file
    public static func loadFromFile(_ url: URL) throws -> FloatWaveformQuaternion {
        return try load(from: url)
    }

    /// Load from CSV file with Float precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> FloatWaveformQuaternion {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}
