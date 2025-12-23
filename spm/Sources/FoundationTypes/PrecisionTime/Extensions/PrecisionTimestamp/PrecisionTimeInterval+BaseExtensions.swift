import Foundation

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension PrecisionTimeInterval: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        let signString = sign == .negative ? "-" : "+"

        if attoseconds == 0 {
            return "\(signString)\(seconds)s"
        }

        // Format attoseconds as 18-digit fractional part
        let fractionalString = String(format: "%018llu", attoseconds)

        // Trim trailing zeros for readability
        let trimmed = fractionalString.trimmingCharacters(in: CharacterSet(charactersIn: "0"))

        return "\(signString)\(seconds).\(trimmed)s"
    }
    
    public var debugDescription: String {
        "PrecisionTimeInterval(seconds: \(seconds), attoseconds: \(attoseconds), sign: .\(sign))"
    }
    
}

// MARK: - Hashable

extension PrecisionTimeInterval: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
        hasher.combine(sign)
    }
}

// MARK: - Equatable

extension PrecisionTimeInterval: Equatable {
    @inlinable
    public static func == (lhs: PrecisionTimeInterval, rhs: PrecisionTimeInterval) -> Bool {
        return lhs.storage == rhs.storage && lhs.sign == rhs.sign
    }
}
