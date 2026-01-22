import Foundation

/// A protocol for sending outbound messages.
///
/// Conforming types provide a mechanism to transmit messages
/// to a remote endpoint (socket, serial port, etc.).
///
/// Implementers choose whether to work with `Data` or `String`:
/// - For binary protocols or most pipe implementations, implement `send(_:Data, priority:)`
/// - For text-based protocols, implement `send(_:String, priority:)`
///
/// Default implementations bridge between the two, so only one needs to be implemented.
///
/// This is the outbound complement to `MessageHandling` (inbound).
public protocol MessageSendable: AnyObject, Sendable {
    /// Sends data to the remote endpoint.
    ///
    /// - Parameters:
    ///   - data: The data to send.
    ///   - priority: Optional priority for queue ordering. Higher values = higher priority.
    /// - Returns: Whether the data was sent or queued successfully.
    @discardableResult
    func send(_ data: Data, priority: Int) -> Bool

    /// Sends a string message to the remote endpoint.
    ///
    /// - Parameters:
    ///   - message: The string message to send.
    ///   - priority: Optional priority for queue ordering. Higher values = higher priority.
    /// - Returns: Whether the message was sent or queued successfully.
    @discardableResult
    func send(_ message: String, priority: Int) -> Bool
}
