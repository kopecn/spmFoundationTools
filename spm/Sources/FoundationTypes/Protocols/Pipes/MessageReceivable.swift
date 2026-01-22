import Foundation

/// A protocol for receiving inbound messages via callback assignment.
///
/// Conforming types allow a message handler to be assigned for processing
/// incoming messages. This complements `MessageHandling` by providing
/// the assignment mechanism rather than the handling itself.
///
/// Implementers choose whether to work with `Data` or `String`:
/// - For binary protocols or most pipe implementations, implement `setDataMessageHandler(_:)`
/// - For text-based protocols, implement `setStringMessageHandler(_:)`
///
/// Default implementations bridge between the two, so only one needs to be implemented.
public protocol MessageReceivable: AnyObject, Sendable {
    /// Assigns a handler for incoming data.
    ///
    /// - Parameter handler: The handler to receive data, or nil to clear.
    func setDataMessageHandler(_ handler: (@Sendable (Data) -> Void)?)

    /// Assigns a handler for incoming string messages.
    ///
    /// - Parameter handler: The handler to receive string messages, or nil to clear.
    func setStringMessageHandler(_ handler: (@Sendable (String) -> Void)?)
}
