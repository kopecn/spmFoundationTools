import Foundation

// MARK: - Codable Support
extension WaveformSpatialPose: Codable where T: BinaryFloatingPoint {

    private enum CodingKeys: String, CodingKey {
        case positions
        case quaternions
        case dt
        case t0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        positions = try container.decode([Position<T>].self, forKey: .positions)
        quaternions = try container.decode([Quaternion<T>].self, forKey: .quaternions)
        dt = try container.decode(PrecisionTimeInterval.self, forKey: .dt)
        t0 = try container.decodeIfPresent(PrecisionTimestamp.self, forKey: .t0)

        // Validate dt is positive
        guard dt > .zero else {
            throw WaveformCodingError.invalidFileFormat
        }

        // Note: We allow positions and quaternions to have different counts for flexibility
        // The isValid property can be used to check if they match
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(positions, forKey: .positions)
        try container.encode(quaternions, forKey: .quaternions)
        try container.encode(dt, forKey: .dt)
        try container.encodeIfPresent(t0, forKey: .t0)
    }
}

// MARK: - File Loading/Saving
extension WaveformSpatialPose {

    /// Load a WaveformSpatialPose from a JSON file at the specified URL
    /// - Parameter url: The URL of the JSON file to load
    /// - Returns: A decoded WaveformSpatialPose instance
    /// - Throws: Decoding errors or file reading errors
    public static func load(from url: URL) throws -> WaveformSpatialPose<T> {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformSpatialPose<T>.self, from: data)
    }

    /// Save the WaveformSpatialPose to a JSON file at the specified URL
    /// - Parameter url: The URL where the JSON file should be saved
    /// - Throws: Encoding errors or file writing errors
    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    /// Create a WaveformSpatialPose from JSON data
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded WaveformSpatialPose instance
    /// - Throws: Decoding errors
    public static func from(jsonData data: Data) throws -> WaveformSpatialPose<T> {
        let decoder = JSONDecoder()
        return try decoder.decode(WaveformSpatialPose<T>.self, from: data)
    }

    /// Convert the WaveformSpatialPose to JSON data
    /// - Returns: JSON data representation of the waveform
    /// - Throws: Encoding errors
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    /// Convert the WaveformSpatialPose to a JSON string
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

// MARK: - Pose-Specific File Operations
extension WaveformSpatialPose where T: BinaryFloatingPoint {

    /// Export to CSV format with pose components as columns
    /// - Parameter url: The URL where the CSV file should be saved
    /// - Throws: File writing errors
    public func exportToCSV(
            to url: URL,
            fullPrecision: Bool = false
        ) throws {
        var csvContent = fullPrecision ? "seconds,attoseconds,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w\n" : "timestamp,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w\n"

        for index in 0..<sampleCount {
            let time: PrecisionTimeInterval = dt * index + (t0?.interval ?? .zero)
            let position = positions[index]
            let quaternion = quaternions[index]

            if fullPrecision {
                csvContent +=
                    "\(time.descriptionSeconds),\(time.attoseconds),\(position.x),\(position.y),\(position.z),\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)\n"
            } else {
                csvContent +=
                    "\(time),\(position.x),\(position.y),\(position.z),\(quaternion.x),\(quaternion.y),\(quaternion.z),\(quaternion.w)\n"
            }
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Add this extension to constrain the CSV import to types that can be parsed from strings:

extension WaveformSpatialPose where T: LosslessStringConvertible & BinaryFloatingPoint {
    /// Import from CSV format
    /// - Parameters:
    ///   - url: The URL of the CSV file to load
    ///   - hasHeader: Whether the CSV file has a header row (default: true)
    /// - Returns: A WaveformSpatialPose created from the CSV data
    /// - Throws: File reading errors or parsing errors
    public static func importFromCSV(
        from url: URL,
        hasHeader: Bool = true
    ) throws -> WaveformSpatialPose<T> {
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
            isFullPrecision = firstLine.count >= 9
            dataLines = lines
        }

        var positions: [Position<T>] = []
        var quaternions: [Quaternion<T>] = []
        var timeIntervals: [PrecisionTimeInterval] = []

        for line in dataLines {
            let components = line.components(separatedBy: ",")

            if isFullPrecision {
                // Format: seconds,attoseconds,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w
                guard components.count >= 9 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                guard let seconds = UInt64(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let attoseconds = UInt64(components[1].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                let time = PrecisionTimeInterval(seconds: seconds, attoseconds: attoseconds, sign: .positive)
                timeIntervals.append(time)

                // Parse position and quaternion values
                guard let posX = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let posY = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let posZ = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatX = T(components[5].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatY = T(components[6].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatZ = T(components[7].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatW = T(components[8].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "seconds,attoseconds,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                positions.append(Position<T>(x: posX, y: posY, z: posZ))
                quaternions.append(Quaternion<T>(x: quatX, y: quatY, z: quatZ, w: quatW))
            } else {
                // Format: timestamp,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w
                guard components.count >= 8 else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                guard let timestamp = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                let time = PrecisionTimeInterval(seconds: timestamp)
                timeIntervals.append(time)

                // Parse position and quaternion values
                guard let posX = T(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let posY = T(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let posZ = T(components[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatX = T(components[4].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatY = T(components[5].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatZ = T(components[6].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let quatW = T(components[7].trimmingCharacters(in: .whitespacesAndNewlines))
                else {
                    throw WaveformCodingError.invalidCSVFormat(expected: "timestamp,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w")
                }

                positions.append(Position<T>(x: posX, y: posY, z: posZ))
                quaternions.append(Quaternion<T>(x: quatX, y: quatY, z: quatZ, w: quatW))
            }
        }

        guard !timeIntervals.isEmpty, timeIntervals.count > 1 else {
            throw WaveformCodingError.insufficientData
        }

        // Calculate dt from the difference between first two timestamps
        let dt = timeIntervals.count > 1 ? timeIntervals[1] - timeIntervals[0] : .oneSecond
        let t0 = PrecisionTimestamp(interval: timeIntervals[0])

        return WaveformSpatialPose<T>(positions: positions, quaternions: quaternions, dt: dt, t0: t0)
    }
}

// MARK: - Convenience Extensions for Common Types
extension DoubleWaveformSpatialPose {
    /// Load a DoubleWaveformSpatialPose from a JSON file
    public static func loadFromFile(_ url: URL) throws -> DoubleWaveformSpatialPose {
        return try load(from: url)
    }

    /// Load from CSV file with Double precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> DoubleWaveformSpatialPose {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}

extension FloatWaveformSpatialPose {
    /// Load a FloatWaveformSpatialPose from a JSON file
    public static func loadFromFile(_ url: URL) throws -> FloatWaveformSpatialPose {
        return try load(from: url)
    }

    /// Load from CSV file with Float precision
    public static func loadFromCSV(_ url: URL, hasHeader: Bool = true) throws -> FloatWaveformSpatialPose {
        return try importFromCSV(from: url, hasHeader: hasHeader)
    }
}
