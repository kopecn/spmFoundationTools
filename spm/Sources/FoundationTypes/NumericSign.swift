/// Internal sign representation
public enum NumericSign: String, Codable, Sendable, Hashable {
    case positive
    case negative
    case zero

    // MARK: - Initializers from Numeric Types
    
    @inlinable
    public init<T: Numeric & Comparable>(_ value: T) {
        if value > 0 {
            self = .positive
        } else if value < 0 {
            self = .negative
        } else {
            self = .zero
        }
    }
}