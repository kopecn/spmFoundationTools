import Foundation

// MARK: - Codable
extension PrecisionTimeInterval: Codable {

    enum CodingKeys: String, CodingKey {
        case seconds
        case attoseconds
        case sign
        case frequencyOffset
        case phaseJitter
        case wander
        case temperatureDrift
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(UInt64.self, forKey: .seconds)
        let attoseconds = try container.decode(UInt64.self, forKey: .attoseconds)
        let sign = try container.decode(NumericSign.self, forKey: .sign)

        self.storage = SIMD2(seconds, attoseconds)
        self.sign = sign

        // Decode calibration metadata (all optional)
        self.frequencyOffset = try container.decodeIfPresent(FrequencyOffset.self, forKey: .frequencyOffset)
        self.phaseJitter = try container.decodeIfPresent(PhaseJitter.self, forKey: .phaseJitter)
        self.wander = try container.decodeIfPresent(Wander.self, forKey: .wander)
        self.temperatureDrift = try container.decodeIfPresent(TemperatureDrift.self, forKey: .temperatureDrift)

        Self.normalize(&self.storage, &self.sign)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seconds, forKey: .seconds)
        try container.encode(attoseconds, forKey: .attoseconds)
        try container.encode(sign, forKey: .sign)

        // Encode calibration metadata (only if present)
        try container.encodeIfPresent(frequencyOffset, forKey: .frequencyOffset)
        try container.encodeIfPresent(phaseJitter, forKey: .phaseJitter)
        try container.encodeIfPresent(wander, forKey: .wander)
        try container.encodeIfPresent(temperatureDrift, forKey: .temperatureDrift)
    }
}
