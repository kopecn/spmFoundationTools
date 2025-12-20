import Foundation

// MARK: - Codable Implementation

/// Conformance to `Codable` for the `Quaternion` type.
/// 
/// This extension enables encoding and decoding of quaternions to and from formats such as JSON.
/// The x, y, z, and w components are encoded as separate fields.
/// 
/// Example encoding output:
/// ```json
/// {
///   "x": 0.0,
///   "y": 0.0,
///   "z": 0.0,
///   "w": 1.0
/// }
/// ```
///
/// Example usage:
/// ```swift
/// let q = Quaternion<Double>(x: 0, y: 0, z: 0, w: 1)
/// let data = try JSONEncoder().encode(q)
/// let decoded = try JSONDecoder().decode(Quaternion<Double>.self, from: data)
/// ```
extension Quaternion {
    private enum CodingKeys: String, CodingKey {
        case x, y, z, w
    }

    /// Creates a `Quaternion` instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let z = try container.decode(T.self, forKey: .z)
        let w = try container.decode(T.self, forKey: .w)

        self.init(x: x, y: y, z: z, w: w)
    }

    /// Encodes this `Quaternion` instance into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
        try container.encode(w, forKey: .w)
    }
}