/// Operational state of a resource managed by a ``TransactionHandler``.
///
/// The resource state reflects both connectivity and operational readiness,
/// allowing callers to determine whether commands can be accepted.
public enum ResourceState: String, Codable, Sendable {

    /// Resource is not connected or communication has not been established.
    case disconnected

    /// Resource is connected and ready to accept commands.
    case idle

    /// Resource is executing a serial command and is occupied.
    ///
    /// Serial commands are blocking; additional serial commands will be queued.
    /// Parallel commands may still be accepted depending on resource capability.
    case busy

    /// Resource is in an error state and cannot accept commands.
    ///
    /// Recovery may require explicit reset or reconnection.
    case error

    /// Resource is in emergency stop state.
    ///
    /// All motion is halted. Manual intervention may be required.
    case estop

    /// Resource is initializing or performing startup routines.
    case initializing
}
