import Foundation

// MARK: - Codable Support
extension Waveform1D: Codable where T: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case values
        case dt
        case t0
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        values = try container.decode([T].self, forKey: .values)
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
extension Waveform1D where T: Codable {
    
    /// Load a Waveform1D from a JSON file at the specified URL
    /// - Parameter url: The URL of the JSON file to load
    /// - Returns: A decoded Waveform1D instance
    /// - Throws: Decoding errors or file reading errors
    public static func load(from url: URL) throws -> Waveform1D<T> {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        // Use milliseconds since 1970 for better precision
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        return try decoder.decode(Waveform1D<T>.self, from: data)
    }
    
    /// Save the Waveform1D to a JSON file at the specified URL
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
    
    /// Create a Waveform1D from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded Waveform1D instance
    /// - Throws: Decoding errors
    public static func from(jsonData data: Data) throws -> Waveform1D<T> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(Waveform1D<T>.self, from: data)
    }
    
    /// Convert the Waveform1D to JSON data
    /// - Returns: JSON data representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return try encoder.encode(self)
    }
    
    /// Convert the Waveform1D to a JSON string
    /// - Returns: JSON string representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw WaveformCodingError.stringConversionFailed
        }
        return string
    }
}

// MARK: - Coding Errors
public enum WaveformCodingError: Error, LocalizedError {
    case stringConversionFailed
    case invalidFileFormat
    case missingRequiredField(String)
    
    public var errorDescription: String? {
        switch self {
        case .stringConversionFailed:
            return "Failed to convert JSON data to string"
        case .invalidFileFormat:
            return "Invalid file format for waveform data"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}

// MARK: - Convenience Extensions for Common Types
extension DoubleWaveform1D {
    /// Load a DoubleWaveform1D from a JSON file
    public static func loadFromFile(_ url: URL) throws -> DoubleWaveform1D {
        return try load(from: url)
    }
}

extension FloatWaveform1D {
    /// Load a FloatWaveform1D from a JSON file
    public static func loadFromFile(_ url: URL) throws -> FloatWaveform1D {
        return try load(from: url)
    }
}

extension IntWaveform1D {
    /// Load an IntWaveform1D from a JSON file
    public static func loadFromFile(_ url: URL) throws -> IntWaveform1D {
        return try load(from: url)
    }
}