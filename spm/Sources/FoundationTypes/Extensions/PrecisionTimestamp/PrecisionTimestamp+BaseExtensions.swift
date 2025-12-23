import Foundation

extension PrecisionTimestamp: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        let date = asFoundationDate
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.string(from: date) + " (\(secondsSinceEpoch)s + \(attosecondsOfSecond)as)"

    }

    public var debugDescription: String {
        return "PrecisionTimestamp(secondsSinceEpoch: \(secondsSinceEpoch), attosecondsOfSecond: \(attosecondsOfSecond))"
    }
}

// MARK: - Hashable

extension PrecisionTimestamp: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

// MARK: - Equatable

extension PrecisionTimestamp: Equatable {
    @inlinable
    public static func == (lhs: PrecisionTimestamp, rhs: PrecisionTimestamp) -> Bool {
        return lhs.storage == rhs.storage
    }
}

// MARK: - Comparable
extension PrecisionTimestamp: Comparable {

    @inlinable
    public static func < (lhs: PrecisionTimestamp, rhs: PrecisionTimestamp) -> Bool {
        if lhs.secondsSinceEpoch != rhs.secondsSinceEpoch {
            return lhs.secondsSinceEpoch < rhs.secondsSinceEpoch
        }
        return lhs.attosecondsOfSecond < rhs.attosecondsOfSecond
    }
}
