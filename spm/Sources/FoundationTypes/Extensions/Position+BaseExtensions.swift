import Foundation


// MARK: - Equatable
extension Position: Equatable {
    public static func == (lhs: Position<T>, rhs: Position<T>) -> Bool {
        return lhs.vector == rhs.vector
    }
}

// MARK: - Hashable
extension Position: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x)
        hasher.combine(vector.y)
        hasher.combine(vector.z)
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Position: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Position(x: \(x), y: \(y), z: \(z))"
    }

    public var debugDescription: String {
        return "Position<\(T.self)>(x: \(x), y: \(y), z: \(z))"
    }
}