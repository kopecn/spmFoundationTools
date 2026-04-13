import Foundation
import OpenCombine

/// A transaction wrapping a command sent to a resource.
///
/// Tracks the full lifecycle of a command from submission through completion,
/// including timing, state transitions, and response handling.
public final class Transaction<Command: TransactionalCommand>: @unchecked Sendable {

    /// Unique identifier for this transaction.
    public let id: Int

    /// The command being transacted.
    public let command: Command

    /// The concurrency category of the command.
    public var category: TransactionConcurrency { command.commandType }

    /// Current state of the transaction.
    public var state: TransactionState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }
    private var _state: TransactionState

    /// Timestamp when the transaction was created.
    public let createdAt: Date

    /// Timestamp when the transaction was sent to the resource.
    public private(set) var sentAt: Date?

    /// Timestamp when the acknowledgment was received.
    public private(set) var acknowledgedAt: Date?

    /// Timestamp when the transaction completed (success or failure).
    public private(set) var completedAt: Date?

    /// The response received from the resource, if any.
    public private(set) var response: String?

    /// The error if the transaction failed.
    public private(set) var error: TransactionError?

    /// Timeout duration for this transaction in seconds.
    public let timeout: TimeInterval

    /// Publisher that emits state changes for this transaction.
    public let statePublisher: OpenCombine.CurrentValueSubject<TransactionState, Never>

    /// Publisher that emits the final result when the transaction completes.
    public let resultPublisher: OpenCombine.PassthroughSubject<TransactionResult, Never>

    /// Publisher that emits solicited events associated with this transaction.
    ///
    /// Solicited events are updates from the resource during command execution,
    /// such as progress updates, waypoint notifications, or streaming data.
    public let eventPublisher: OpenCombine.PassthroughSubject<TransactionEvent, Never>

    /// All events received for this transaction, in order.
    public private(set) var events: [TransactionEvent] = []

    private let lock = NSLock()

    /// Creates a new transaction for the given command.
    ///
    /// - Parameters:
    ///   - id: Unique transaction identifier.
    ///   - command: The command to transact.
    ///   - timeout: Timeout duration in seconds. Defaults to command's timeout or 30 seconds.
    public init(id: Int, command: Command, timeout: TimeInterval? = nil) {
        self.id = id
        self.command = command
        self._state = .pending
        self.createdAt = Date()
        self.timeout = timeout ?? TimeInterval(command.timeout ?? 30.0)
        self.statePublisher = CurrentValueSubject(.pending)
        self.resultPublisher = PassthroughSubject()
        self.eventPublisher = PassthroughSubject()
    }

    func markSent() {
        lock.lock()
        sentAt = Date()
        _state = .awaitingAck
        lock.unlock()
        statePublisher.send(.awaitingAck)
    }

    func markAcknowledged() {
        lock.lock()
        acknowledgedAt = Date()
        _state = .executing
        lock.unlock()
        statePublisher.send(.executing)
        resultPublisher.send(.acknowledged(transactionID: id))
    }

    func markQueued(position: Int) {
        lock.lock()
        _state = .queued
        lock.unlock()
        statePublisher.send(.queued)
        resultPublisher.send(.queued(transactionID: id, position: position))
    }

    func markCompleted(response: String? = nil) {
        lock.lock()
        self.response = response
        completedAt = Date()
        _state = .completed
        lock.unlock()
        statePublisher.send(.completed)
        resultPublisher.send(.completed(transactionID: id, response: response))
        resultPublisher.send(completion: .finished)
        eventPublisher.send(completion: .finished)
    }

    func markFailed(error: TransactionError) {
        lock.lock()
        self.error = error
        completedAt = Date()
        _state = .failed
        lock.unlock()
        statePublisher.send(.failed)
        resultPublisher.send(.failed(transactionID: id, error: error))
        resultPublisher.send(completion: .finished)
        eventPublisher.send(completion: .finished)
    }

    func markTimedOut() {
        lock.lock()
        let errorType: TransactionError = _state == .awaitingAck ? .acknowledgmentTimeout : .responseTimeout
        self.error = errorType
        completedAt = Date()
        _state = .timedOut
        lock.unlock()
        statePublisher.send(.timedOut)
        resultPublisher.send(.timedOut(transactionID: id))
        resultPublisher.send(completion: .finished)
        eventPublisher.send(completion: .finished)
    }

    func markCancelled() {
        lock.lock()
        self.error = .cancelled
        completedAt = Date()
        _state = .cancelled
        lock.unlock()
        statePublisher.send(.cancelled)
        resultPublisher.send(.failed(transactionID: id, error: .cancelled))
        resultPublisher.send(completion: .finished)
        eventPublisher.send(completion: .finished)
    }

    func receiveEvent(_ event: TransactionEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
        eventPublisher.send(event)
    }

    /// Elapsed time since the transaction was sent, or nil if not yet sent.
    public var elapsedSinceSent: TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        guard let sentAt = sentAt else { return nil }
        return Date().timeIntervalSince(sentAt)
    }

    /// Whether the transaction has exceeded its timeout.
    public var isTimedOut: Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let sentAt = sentAt else { return false }
        return Date().timeIntervalSince(sentAt) > timeout
    }

    /// Whether the transaction is in a terminal state (completed, failed, cancelled, timedOut).
    public var isTerminal: Bool {
        lock.lock()
        defer { lock.unlock() }
        switch _state {
        case .completed, .failed, .cancelled, .timedOut:
            return true
        case .pending, .awaitingAck, .executing, .queued:
            return false
        }
    }

}

// MARK: - Hashable

extension Transaction: Hashable {
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
