import Foundation

// MARK: - Codable
extension PrecisionTimestamp: Codable {

    enum CodingKeys: String, CodingKey {
        case secondsSinceEpoch
        case attosecondsOfSecond
        case timescale
        case referenceFrame
        case uncertainty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(UInt64.self, forKey: .secondsSinceEpoch)
        let attoseconds = try container.decode(UInt64.self, forKey: .attosecondsOfSecond)
        let timescale = try container.decodeIfPresent(Timescale.self, forKey: .timescale)
        let referenceFrame = try container.decodeIfPresent(ReferenceFrame.self, forKey: .referenceFrame)
        let uncertainty = try container.decodeIfPresent(UInt64.self, forKey: .uncertainty)
        self.init(
            secondsSinceEpoch: seconds,
            attosecondsOfSecond: attoseconds,
            timescale: timescale,
            referenceFrame: referenceFrame,
            uncertainty: uncertainty
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secondsSinceEpoch, forKey: .secondsSinceEpoch)
        try container.encode(attosecondsOfSecond, forKey: .attosecondsOfSecond)
        try container.encodeIfPresent(timescale, forKey: .timescale)
        try container.encodeIfPresent(referenceFrame, forKey: .referenceFrame)
        try container.encodeIfPresent(uncertainty, forKey: .uncertainty)
    }
}
