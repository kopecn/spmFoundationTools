import Foundation

extension PrecisionTimestamp: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        let date = asFoundationDate
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let signString = sign == .negative ? "-" : ""
        var result = isoFormatter.string(from: date) + " (\(signString)\(seconds)s + \(attoseconds)as)"

        if let timescale = timescale {
            result += " [\(timescale.rawValue)]"
        }
        if let referenceFrame = referenceFrame {
            result += " @\(referenceFrame.rawValue)"
        }
        if let uncertainty = uncertainty {
            result += " ±\(uncertainty)as"
        }

        return result
    }

    public var debugDescription: String {
        var result = "PrecisionTimestamp(interval: \(interval.debugDescription)"

        if let timescale = timescale {
            result += ", timescale: .\(timescale)"
        }
        if let referenceFrame = referenceFrame {
            result += ", referenceFrame: .\(referenceFrame)"
        }
        if let uncertainty = uncertainty {
            result += ", uncertainty: \(uncertainty)"
        }

        result += ")"
        return result
    }
}

// MARK: - Hashable

extension PrecisionTimestamp: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(interval.seconds)
        hasher.combine(interval.attoseconds)
        hasher.combine(interval.sign)
        hasher.combine(timescale)
        hasher.combine(referenceFrame)
        hasher.combine(uncertainty)
    }
}

// MARK: - Equatable

extension PrecisionTimestamp: Equatable {
    @inlinable
    public static func == (lhs: PrecisionTimestamp, rhs: PrecisionTimestamp) -> Bool {
        return lhs.interval == rhs.interval
            && lhs.timescale == rhs.timescale
            && lhs.referenceFrame == rhs.referenceFrame
            && lhs.uncertainty == rhs.uncertainty
    }
}

// // MARK: - Comparable
// extension PrecisionTimestamp {

//     func compareSafely(to other: PrecisionTimestamp) -> Result<ComparisonResult, TimestampError> {
//         // Check time scale
//         guard timescale == other.timescale else {
//             return .failure(.incompatibleTimeScale)
//         }

//         // Check reference frame
//         guard referenceFrame == other.referenceFrame else {
//             return .failure(.incompatibleReferenceFrame)
//         }

//         // Check uncertainty overlap
//         let delta = storage - other.storage

//         if let combinedUncertainty = uncertainty + other.uncertainty {
//             if abs(delta) <= combinedUncertainty {
//                 return .failure(.overlappingUncertainty)
//             }
//         }

//         // Return proper ComparisonResult
//         if delta < 0 {
//             return .success(.orderedAscending)
//         } else {
//             return .success(.orderedDescending)
//         }
//     }

// }
