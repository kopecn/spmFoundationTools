import Foundation

/// A protocol for receiving inbound messages via callback assignment.
///
/// Conforming types allow a message handler to be assigned for processing
/// incoming messages. This complements `MessageHandling` by providing
/// the assignment mechanism rather than the handling itself.
public protocol MessageReceivable: AnyObject, Sendable {
    /// The type of handler that processes incoming messages.
    associatedtype Handler

    /// Assigns a handler for incoming messages.
    ///
    /// - Parameter handler: The handler to receive messages, or nil to clear.
    func setMessageHandler(_ handler: Handler?)
}
