import Foundation

// MARK: - Codable Implementation

/// Conformance to `Codable` for the `SpatialPose` type.
/// 
/// This extension enables encoding and decoding of spatial poses to and from formats such as JSON.
/// The position (`x`, `y`, `z`) and rotation quaternion (`qx`, `qy`, `qz`, `qw`) components are encoded as separate fields.
/// 
/// Example encoding output:
/// ```json
/// {
///   "x": 1.0,
///   "y": 2.0,
///   "z": 3.0,
///   "qx": 0.0,
///   "qy": 0.0,
///   "qz": 0.0,
///   "qw": 1.0
/// }
/// ```
///
/// Example usage:
/// ```swift
/// let pose = SpatialPose<Double>(x: 1, y: 2, z: 3, qx: 0, qy: 0, qz: 0, qw: 1)
/// let data = try JSONEncoder().encode(pose)
/// let decoded = try JSONDecoder().decode(SpatialPose<Double>.self, from: data)
/// ```
extension SpatialPose {
    private enum CodingKeys: String, CodingKey {
        case x, y, z
        case qx, qy, qz, qw
    }

    /// Creates a `SpatialPose` instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let z = try container.decode(T.self, forKey: .z)
        let qx = try container.decode(T.self, forKey: .qx)
        let qy = try container.decode(T.self, forKey: .qy)
        let qz = try container.decode(T.self, forKey: .qz)
        let qw = try container.decode(T.self, forKey: .qw)

        self.init(x: x, y: y, z: z, qx: qx, qy: qy, qz: qz, qw: qw)
    }

    /// Encodes this `SpatialPose` instance into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
        try container.encode(qx, forKey: .qx)
        try container.encode(qy, forKey: .qy)
        try container.encode(qz, forKey: .qz)
        try container.encode(qw, forKey: .qw)
    }
}
