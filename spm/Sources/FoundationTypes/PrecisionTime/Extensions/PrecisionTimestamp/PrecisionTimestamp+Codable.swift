import Foundation

// MARK: - Codable
extension PrecisionTimestamp: Codable {

    enum CodingKeys: String, CodingKey {
        case seconds
        case attoseconds
        case sign
        case timescale
        case referenceFrame
        case uncertainty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(UInt64.self, forKey: .seconds)
        let attoseconds = try container.decode(UInt64.self, forKey: .attoseconds)
        let sign = try container.decode(NumericSign.self, forKey: .sign)
        let timescale = try container.decodeIfPresent(Timescale.self, forKey: .timescale)
        let referenceFrame = try container.decodeIfPresent(ReferenceFrame.self, forKey: .referenceFrame)
        let uncertainty = try container.decodeIfPresent(UInt64.self, forKey: .uncertainty)

        self.interval = PrecisionTimeInterval(
            seconds: seconds,
            attoseconds: attoseconds,
            sign: sign
        )
        self.timescale = timescale
        self.referenceFrame = referenceFrame
        self.uncertainty = uncertainty
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seconds, forKey: .seconds)
        try container.encode(attoseconds, forKey: .attoseconds)
        try container.encode(sign, forKey: .sign)
        try container.encodeIfPresent(timescale, forKey: .timescale)
        try container.encodeIfPresent(referenceFrame, forKey: .referenceFrame)
        try container.encodeIfPresent(uncertainty, forKey: .uncertainty)
    }
}
