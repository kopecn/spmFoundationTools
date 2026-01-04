import Foundation

// MARK: - Codable Support
extension WaveformPosition: Codable where T: BinaryFloatingPoint {

    private enum CodingKeys: String, CodingKey {
        case values
        case dt
        case t0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        values = try container.decode([Position<T>].self, forKey: .values)
        dt = try container.decode(PrecisionTimeInterval.self, forKey: .dt)
        t0 = try container.decodeIfPresent(PrecisionTimestamp.self, forKey: .t0)

        // Validate dt is positive
        guard dt > .zero else {
            throw WaveformCodingError.invalidFileFormat
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(values, forKey: .values)
        try container.encode(dt, forKey: .dt)
        try container.encodeIfPresent(t0, forKey: .t0)
    }
}

// MARK: - File Loading/Saving
extension WaveformPosition {

    /// Load a WaveformPosition from a JSON file at the specified URL
    /// - Parameter url: The URL of the JSON file to load
    /// - Returns: A decoded WaveformPosition instance
    /// - Throws: Decoding errors or file reading errors
    public static func load(from url: URL) throws -> WaveformPosition<T> {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformPosition<T>.self, from: data)
    }

    /// Save the WaveformPosition to a JSON file at the specified URL
    /// - Parameter url: The URL where the JSON file should be saved
    /// - Throws: Encoding errors or file writing errors
    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    /// Create a WaveformPosition from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded WaveformPosition instance
    /// - Throws: Decoding errors
    public static func from(jsonData data: Data) throws -> WaveformPosition<T> {
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformPosition<T>.self, from: data)
    }

    /// Convert the WaveformPosition to JSON data
    /// - Returns: JSON data representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    /// Convert the WaveformPosition to a JSON string
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

// MARK: - Position-Specific File Operations
extension WaveformPosition {

    /// Export to CSV format with position components as columns
    /// - Parameter url: The URL where the CSV file should be saved
    /// - Throws: File writing errors
    public func exportToCSV(
        to url: URL,
        fullPrecision: Bool = false
    ) throws {
        var csvContent = fullPrecision ? "seconds,attoseconds,x,y,z\n" : "timestamp,x,y,z\n"

        for (index, position) in values.enumerated() {
            let time: PrecisionTimeInterval = dt * index + (t0?.interval ?? .zero)
            if fullPrecision {
                csvContent += "\(time.descriptionSeconds),\(time.attoseconds),\(position.x),\(position.y),\(position.z)\n"
            } else {
                csvContent += "\(time),\(position.x),\(position.y),\(position.z)\n"
            }
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Add this extension to constrain the CSV import to types that can be parsed from strings:

extension WaveformPosition where T: LosslessStringConvertible & BinaryFloatingPoint {
    /// Import from CSV format
    /// - Parameters:
    ///   - url: The URL of the CSV file to load
    ///   - hasHeader: Whether the CSV file has a header row (default: true)
    /// - Returns: A WaveformPosition created from the CSV data
    /// - Throws: File reading errors or parsing errors
    public static func importFromCSV(
        from url: URL,
        hasHeader: Bool = true
    ) throws -> WaveformPosition<T> {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw WaveformCodingError.emptyCSVFile
        }

        // Detect if this is a full precision CSV by checking the header
        let isFullPrecision: Bool
        let dataLines: [String]

        if hasHeader {
            let header = lines[0].lowercased()
            isFullPrecision = header.contains("seconds") && header.contains("attoseconds")
            dataLines = Array(lines.dropFirst())
        } else {
            // Without a header, we need to guess based on the number of columns
            let firstLine = lines[0].components(separatedBy: ",")
            isFullPrecision = firstLine.count >= 5
            dataLines = lines
        }

        var positions: [Position<T>] = []
        var timeIntervals: [PrecisionTimeInterval] = []

        for line in dataLines {
            let components = line.components(separatedBy: ",")

            if isFullPrecision {
                // Format: seconds,attoseconds,x,y,z
                guard components.count >= 5 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z")
                }

                guard let seconds = UInt64(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let attoseconds = UInt64(components[1].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z")
                }

                let time = PrecisionTimeInterval(seconds: seconds, attoseconds: attoseconds, sign: .positive)
                timeIntervals.append(time)

                // Parse position values (x, y, z)
                guard let x = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let y = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let z = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z")
                }

                positions.append(Position<T>(x: x, y: y, z: z))
            } else {
                // Format: timestamp,x,y,z
                guard components.count >= 4 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z")
                }

                guard let timestamp = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z")
                }

                let time = PrecisionTimeInterval(seconds: timestamp)
                timeIntervals.append(time)

                // Parse position values (x, y, z)
                guard let x = T(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let y = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let z = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z")
                }

                positions.append(Position<T>(x: x, y: y, z: z))
            }
        }

        guard !timeIntervals.isEmpty, timeIntervals.count > 1 else {
            throw WaveformCodingError.insufficientData
        }

        // Calculate dt from the difference between first two timestamps
        let dt = timeIntervals.count > 1 ? timeIntervals[1] - timeIntervals[0] : .oneSecond
        let t0 = PrecisionTimestamp(interval: timeIntervals[0])

        return WaveformPosition<T>(values: positions, dt: dt, t0: t0)
    }
}

// MARK: - Convenience Extensions for Common Types
extension DoubleWaveformPosition {
    /// Load a DoubleWaveformPosition from a JSON file
    public static func loadFromFile(_ url: URL) throws -> DoubleWaveformPosition {
        return try load(from: url)
    }

    /// Load from CSV file with Double precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> DoubleWaveformPosition {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}

extension FloatWaveformPosition {
    /// Load a FloatWaveformPosition from a JSON file
    public static func loadFromFile(_ url: URL) throws -> FloatWaveformPosition {
        return try load(from: url)
    }

    /// Load from CSV file with Float precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> FloatWaveformPosition {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}
