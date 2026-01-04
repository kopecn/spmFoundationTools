import Foundation

// MARK: - Codable Support
extension WaveformQuaternion: Codable where T: BinaryFloatingPoint {

    private enum CodingKeys: String, CodingKey {
        case values
        case dt
        case t0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        values = try container.decode([Quaternion<T>].self, forKey: .values)
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
extension WaveformQuaternion {

    /// Load a WaveformQuaternion from a JSON file at the specified URL
    /// - Parameter url: The URL of the JSON file to load
    /// - Returns: A decoded WaveformQuaternion instance
    /// - Throws: Decoding errors or file reading errors
    public static func load(from url: URL) throws -> WaveformQuaternion<T> {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformQuaternion<T>.self, from: data)
    }

    /// Save the WaveformQuaternion to a JSON file at the specified URL
    /// - Parameter url: The URL where the JSON file should be saved
    /// - Throws: Encoding errors or file writing errors
    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    /// Create a WaveformQuaternion from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded WaveformQuaternion instance
    /// - Throws: Decoding errors
    public static func from(jsonData data: Data) throws -> WaveformQuaternion<T> {
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformQuaternion<T>.self, from: data)
    }

    /// Convert the WaveformQuaternion to JSON data
    /// - Returns: JSON data representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    /// Convert the WaveformQuaternion to a JSON string
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

// MARK: - Quaternion-Specific File Operations
extension WaveformQuaternion {

    /// Export to CSV format with quaternion components as columns
    /// - Parameter url: The URL where the CSV file should be saved
    /// - Throws: File writing errors
    public func exportToCSV(
        to url: URL,
        fullPrecision: Bool = false
    ) throws {
        var csvContent = fullPrecision ? "seconds,attoseconds,x,y,z,w\n" : "timestamp,x,y,z,w\n"

        for (index, quaternion) in values.enumerated() {
            let time: PrecisionTimeInterval = dt * index + (t0?.interval ?? .zero)
            if fullPrecision {
                csvContent += "\(time.descriptionSeconds),\(time.attoseconds),\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)\n"
            } else {
                csvContent += "\(time),\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)\n"
            }
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Add this extension to constrain the CSV import to types that can be parsed from strings:

extension WaveformQuaternion where T: LosslessStringConvertible & BinaryFloatingPoint {
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
            isFullPrecision = firstLine.count >= 6
            dataLines = lines
        }

        var quaternions: [Quaternion<T>] = []
        var timeIntervals: [PrecisionTimeInterval] = []

        for line in dataLines {
            let components = line.components(separatedBy: ",")

            if isFullPrecision {
                // Format: seconds,attoseconds,x,y,z,w
                guard components.count >= 6 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z,w")
                }

                guard let seconds = UInt64(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let attoseconds = UInt64(components[1].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z,w")
                }

                let time = PrecisionTimeInterval(seconds: seconds, attoseconds: attoseconds, sign: .positive)
                timeIntervals.append(time)

                // Parse quaternion values
                guard let x = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let y = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let z = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let w = T(components[5].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,x,y,z,w")
                }

                quaternions.append(Quaternion<T>(x: x, y: y, z: z, w: w))
            } else {
                // Format: timestamp,x,y,z,w
                guard components.count >= 5 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z,w")
                }

                guard let timestamp = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z,w")
                }

                let time = PrecisionTimeInterval(seconds: timestamp)
                timeIntervals.append(time)

                // Parse quaternion values
                guard let x = T(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let y = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let z = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let w = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,x,y,z,w")
                }

                quaternions.append(Quaternion<T>(x: x, y: y, z: z, w: w))
            }
        }

        guard !timeIntervals.isEmpty, timeIntervals.count > 1 else {
            throw WaveformCodingError.insufficientData
        }

        // Calculate dt from the difference between first two timestamps
        let dt = timeIntervals.count > 1 ? timeIntervals[1] - timeIntervals[0] : .oneSecond
        let t0 = PrecisionTimestamp(interval: timeIntervals[0])

        return WaveformQuaternion<T>(values: quaternions, dt: dt, t0: t0)
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
