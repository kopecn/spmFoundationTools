/// Lifecycle state of a transaction.
public enum TransactionState: String, Codable, Sendable {

    /// Transaction has been created but not yet sent.
    case pending

    /// Transaction has been sent and is awaiting acknowledgment.
    case awaitingAck

    /// Transaction was acknowledged and is executing on the resource.
    case executing

    /// Transaction has been queued behind other transactions.
    case queued

    /// Transaction completed successfully.
    case completed

    /// Transaction failed.
    case failed

    /// Transaction was cancelled.
    case cancelled

    /// Transaction timed out.
    case timedOut
}

/// Result of a transaction submission or execution.
public enum TransactionResult: Sendable {

    /// Transaction was acknowledged and is being processed.
    case acknowledged(transactionID: Int)

    /// Transaction completed successfully with optional response data.
    case completed(transactionID: Int, response: String?)

    /// Transaction failed with an error.
    case failed(transactionID: Int, error: TransactionError)

    /// Transaction timed out before receiving a response.
    case timedOut(transactionID: Int)

    /// Transaction was queued for later execution.
    case queued(transactionID: Int, position: Int)
}

/// Errors that can occur during transaction processing.
public enum TransactionError: Error, Sendable {

    /// Resource is not in a state that accepts commands.
    case resourceNotReady(state: ResourceState)

    /// The command category conflicts with a concurrently running command category.
    case categoryConflict(requested: TransactionConcurrency, current: TransactionConcurrency)

    /// Transaction timed out waiting for acknowledgment.
    case acknowledgmentTimeout

    /// Transaction timed out waiting for completion response.
    case responseTimeout

    /// Resource reported an error during command execution.
    case resourceError(message: String)

    /// Communication with the resource was lost during the transaction.
    case communicationLost

    /// Transaction was cancelled before completion.
    case cancelled

    /// Unknown or unexpected error.
    case unknown(underlying: Error?)
}
