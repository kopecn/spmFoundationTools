import Foundation

/// A protocol for sending outbound messages.
///
/// Conforming types provide a mechanism to transmit string messages
/// to a remote endpoint (socket, serial port, etc.).
///
/// This is the outbound complement to `MessageHandling` (inbound).
public protocol MessageSendable: AnyObject, Sendable {
    /// Sends a message to the remote endpoint.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - priority: Optional priority for queue ordering. Higher values = higher priority.
    /// - Returns: Whether the message was sent or queued successfully.
    @discardableResult
    func send(_ message: String, priority: Int) -> Bool
}

extension MessageSendable {
    /// Sends a message with default priority.
    @discardableResult
    public func send(_ message: String) -> Bool {
        send(message, priority: 0)
    }
}
