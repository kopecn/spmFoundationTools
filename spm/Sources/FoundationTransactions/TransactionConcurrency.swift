/// Describes how a transactional command executes relative to other commands.
///
/// Use this to categorize commands by their concurrency behavior when submitting
/// to a ``TransactionHandler``.
public enum TransactionConcurrency: String, Codable, Sendable, Hashable {

    /// Commands execute one at a time in sequence.
    ///
    /// While a serial command is active, additional serial commands are queued.
    /// Analogous to a blocking, exclusive-resource operation (e.g., a motion
    /// command on a robot arm that physically occupies the workspace).
    case serial

    /// Commands may execute concurrently up to a configurable limit.
    ///
    /// Parallel commands do not block one another. Useful for read-only queries
    /// or operations that do not mutate shared state.
    case parallel

    /// Commands execute one at a time in sequence, independently of ``serial``.
    ///
    /// Exclusive commands have their own queue, separate from serial commands.
    /// This enables two categories of blocking work (e.g., motion vs. configuration
    /// writes) to proceed without cross-blocking.
    case exclusive
}
