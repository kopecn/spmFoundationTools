/// A protocol for commands that can be serialized into transactional protocol format.
///
/// Transactional commands support both terminal-based string serialization
/// (e.g., `<trID,command,arg1,arg2,...>`) and JSON encoding via ``Codable``.
///
/// ## Example Terminal Format
/// ```
/// <123,home,>
/// <456,moveto,1.57,-1.57,0.0,0.0,1.57,0.0>
/// ```
public protocol TransactionalCommand: Codable, Sendable {

    /// The command identifier string.
    var commandString: String { get }

    /// Arguments for the command. Empty array if no arguments.
    var arguments: [String] { get }

    /// Optional timeout in seconds.
    var timeout: Float? { get }

    /// Transaction ID hint for this command.
    ///
    /// When `>= 0`, used directly as the transaction ID. When `< 0`, the
    /// ``TransactionHandler`` generates a unique ID automatically.
    var trID: Int { get }

    /// Concurrency category that governs how this command is scheduled.
    var commandType: TransactionConcurrency { get }

    /// Resource identifier for the target resource.
    ///
    /// Used to route commands to the correct handler and maintain
    /// identification as messages are passed through the system.
    var resourceID: String? { get }

    /// Serializes the command into terminal transaction format.
    ///
    /// - Parameter transactionID: The transaction ID to embed in the serialized output.
    /// - Returns: A string in the format `<transactionID,command,arg1,arg2,...,>`
    func serialize(transactionID: String) -> String
}

// MARK: - Default Implementations

extension TransactionalCommand {
    /// Default implementation returns nil.
    public var resourceID: String? { nil }
}

extension TransactionalCommand {
    /// Default terminal-protocol serialization.
    ///
    /// Formats the command as: `<transactionID,command,arg1,arg2,...,>`
    ///
    /// - Command with no args: `<123,home,>`
    /// - Command with args: `<456,moveto,1.57,-1.57,0.0>`
    public func serialize(transactionID: String) -> String {
        var components = [transactionID, commandString]
        components.append(contentsOf: arguments)
        let content = components.joined(separator: ",")
        return "<\(content),>"
    }
}
