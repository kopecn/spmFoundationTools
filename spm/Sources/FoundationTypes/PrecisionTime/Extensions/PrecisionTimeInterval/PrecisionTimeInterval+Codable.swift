import Foundation

// MARK: - Codable
extension PrecisionTimeInterval: Codable {

    enum CodingKeys: String, CodingKey {
        case seconds
        case attoseconds
        case sign
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(UInt64.self, forKey: .seconds)
        let attoseconds = try container.decode(UInt64.self, forKey: .attoseconds)
        let sign = try container.decode(NumericSign.self, forKey: .sign)

        self.storage = SIMD2(seconds, attoseconds)
        self.sign = sign

        Self.normalize(&self.storage, &self.sign)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seconds, forKey: .seconds)
        try container.encode(attoseconds, forKey: .attoseconds)
        try container.encode(sign, forKey: .sign)
    }
}
