import Foundation

// MARK: - Comparable

extension PrecisionTimestamp: Comparable {
    /// Compares two timestamps using their underlying PrecisionTimeInterval values.
    ///
    /// This implementation delegates to PrecisionTimeInterval's Comparable conformance,
    /// ensuring a single source of truth for time comparisons.
    ///
    /// - Note: This comparison only considers the time values (interval).
    ///         Use `canCompare(to:)` to validate compatibility of timescale and referenceFrame.
    public static func < (lhs: PrecisionTimestamp, rhs: PrecisionTimestamp) -> Bool {
        // Delegate to PrecisionTimeInterval's Comparable implementation
        // This is the single source of truth for time comparisons
        return lhs.interval < rhs.interval
    }
}

// MARK: - Comparison Validation

extension PrecisionTimestamp {

    /// Errors that can occur when validating timestamp comparisons
    public enum ComparisonValidationError: Error, Sendable {
        case incompatibleTimeScale
        case incompatibleReferenceFrame
        case overlappingUncertainty
    }

    /// Check if two timestamps can be meaningfully compared.
    ///
    /// Validates that:
    /// - Time scales are compatible (if specified)
    /// - Reference frames are compatible (if specified)
    ///
    /// - Parameter other: The timestamp to compare against
    /// - Returns: `true` if timestamps are compatible for comparison
    public func canCompare(to other: PrecisionTimestamp) -> Bool {
        // Check time scale compatibility if both are specified
        if let lhsScale = self.timescale, let rhsScale = other.timescale {
            guard lhsScale == rhsScale else {
                return false
            }
        }

        // Check reference frame compatibility if both are specified
        if let lhsFrame = self.referenceFrame, let rhsFrame = other.referenceFrame {
            guard lhsFrame == rhsFrame else {
                return false
            }
        }

        return true
    }

    /// Perform a validated comparison that checks compatibility before comparing.
    ///
    /// This method ensures that the timestamps being compared have compatible
    /// timescales and reference frames.
    ///
    /// - Parameter other: The timestamp to compare against
    /// - Returns: Result containing the comparison result or a validation error
    public func compareValidated(to other: PrecisionTimestamp) -> Result<ComparisonResult, ComparisonValidationError> {
        // Check time scale compatibility
        if let lhsScale = self.timescale, let rhsScale = other.timescale {
            guard lhsScale == rhsScale else {
                return .failure(.incompatibleTimeScale)
            }
        }

        // Check reference frame compatibility
        if let lhsFrame = self.referenceFrame, let rhsFrame = other.referenceFrame {
            guard lhsFrame == rhsFrame else {
                return .failure(.incompatibleReferenceFrame)
            }
        }

        // Check uncertainty overlap if both timestamps have uncertainty
        if let lhsUncertainty = self.uncertainty, let rhsUncertainty = other.uncertainty {
            // Calculate the absolute difference between timestamps
            let delta: PrecisionTimeInterval
            if self.interval < other.interval {
                delta = other.interval - self.interval
            } else {
                delta = self.interval - other.interval
            }

            // Check if combined uncertainties overlap
            let combinedUncertainty = lhsUncertainty + rhsUncertainty

            // If the difference is smaller than combined uncertainty, they overlap
            if delta.seconds == 0 && delta.attoseconds <= combinedUncertainty {
                return .failure(.overlappingUncertainty)
            }
        }

        // Perform comparison using PrecisionTimeInterval's Comparable implementation
        // This ensures single source of truth
        if self.interval < other.interval {
            return .success(.orderedAscending)
        } else if self.interval > other.interval {
            return .success(.orderedDescending)
        } else {
            return .success(.orderedSame)
        }
    }
}

// MARK: - Convenience Checks

extension PrecisionTimestamp {

    /// Check if this timestamp represents the Unix epoch (1970-01-01 00:00:00 UTC)
    @inlinable
    public var isEpoch: Bool {
        return interval.isZero
    }

    /// Check if this timestamp is after the Unix epoch
    @inlinable
    public var isAfterEpoch: Bool {
        return interval.isPositive
    }

    /// Check if this timestamp is before the Unix epoch
    @inlinable
    public var isBeforeEpoch: Bool {
        return interval.isNegative
    }

    /// The Unix epoch timestamp (1970-01-01 00:00:00 UTC)
    @inlinable
    public static var epoch: PrecisionTimestamp {
        return PrecisionTimestamp(
            interval: .zero,
            timescale: nil,
            referenceFrame: nil,
            uncertainty: nil
        )
    }
}
