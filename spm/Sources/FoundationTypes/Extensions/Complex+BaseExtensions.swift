import Foundation


// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Complex: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        if imaginary >= 0 {
            return "\(real) + \(imaginary)i"
        } else {
            return "\(real) - \(-imaginary)i"
        }
    }

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        return "Complex(real: \(real), imaginary: \(imaginary))"
    }
}

// MARK: - Hashable
extension Complex: Hashable where T: Hashable{
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(real)
        hasher.combine(imaginary)
    }
}

// MARK: - Equatable
extension Complex: Equatable {
    @inlinable
    public static func == (lhs: Complex<T>, rhs: Complex<T>) -> Bool {
        return lhs.storage == rhs.storage
    }
}