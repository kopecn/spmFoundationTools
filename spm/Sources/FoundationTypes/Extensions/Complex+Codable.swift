import Foundation

// MARK: - Codable Conformance
extension Complex: Codable where T: Codable {
    enum CodingKeys: String, CodingKey {
        case real
        case imaginary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let real = try container.decode(T.self, forKey: .real)
        let imaginary = try container.decode(T.self, forKey: .imaginary)
        self.init(real: real, imaginary: imaginary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(real, forKey: .real)
        try container.encode(imaginary, forKey: .imaginary)
    }
}
