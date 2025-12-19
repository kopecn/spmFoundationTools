import Foundation

// MARK: - Codable Conformance

/// Conformance to `Codable` for the `Complex` type.
/// 
/// This extension enables encoding and decoding of complex numbers to and from formats such as JSON.
/// The real and imaginary components are encoded as separate fields.
/// 
/// Example encoding output:
/// ```json
/// {
///   "real": 1.0,
///   "imaginary": 2.0
/// }
/// ```
///
/// Example usage:
/// ```swift
/// let z = Complex<Double>(real: 1.0, imaginary: 2.0)
/// let data = try JSONEncoder().encode(z)
/// let decoded = try JSONDecoder().decode(Complex<Double>.self, from: data)
/// ```
extension Complex: Codable where T: Codable {
    enum CodingKeys: String, CodingKey {
        case real
        case imaginary
    }

    /// Creates a `Complex` instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let real = try container.decode(T.self, forKey: .real)
        let imaginary = try container.decode(T.self, forKey: .imaginary)
        self.init(real: real, imaginary: imaginary)
    }

    /// Encodes this `Complex` instance into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(real, forKey: .real)
        try container.encode(imaginary, forKey: .imaginary)
    }
}
