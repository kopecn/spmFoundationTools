import Foundation

// MARK: - Codable
extension PrecisionTimestamp: Codable {

    enum CodingKeys: String, CodingKey {
        case secondsSinceEpoch
        case attosecondsOfSecond
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(UInt64.self, forKey: .secondsSinceEpoch)
        let attoseconds = try container.decode(UInt64.self, forKey: .attosecondsOfSecond)
        self.init(secondsSinceEpoch: seconds, attosecondsOfSecond: attoseconds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secondsSinceEpoch, forKey: .secondsSinceEpoch)
        try container.encode(attosecondsOfSecond, forKey: .attosecondsOfSecond)
    }
}
