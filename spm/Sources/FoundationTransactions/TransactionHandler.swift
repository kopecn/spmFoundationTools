import Foundation
import FoundationInterfaces
import OpenCombine
import OpenCombineDispatch

/// A handler for managing transactional commands with a single resource.
///
/// `TransactionHandler` provides composable transaction management for any resource
/// that communicates via a request/acknowledgment/response protocol, supporting the
/// command flow: cmd → ack → work → response.
///
/// ## Features
/// - **Isolated resource handling**: Each handler manages one resource
/// - **Command categorization**: Serial (blocking), Parallel (concurrent), Exclusive (separate serial queue)
/// - **Timeout management**: Per-transaction and global timeout support
/// - **Resource state tracking**: Monitors resource readiness
/// - **OpenCombine integration**: State and events exposed as publishers
///
/// ## Bidirectional Usage
/// `TransactionHandler` supports both outbound and inbound transaction initiation:
///
/// - **Outbound** (local initiates): call `submit(_:timeout:)` and subscribe to the
///   returned `Transaction`.
/// - **Inbound** (remote initiates): assign `inboundTransactionHandler`. When an inbound
///   message does not match a locally pending transaction ID, it is routed here instead
///   of being silently dropped.
///
/// ## Usage
/// ```swift
/// let handler = TransactionHandler<RobotCommand>(resourceID: "robot-1")
///
/// // Submit a serial command (will be queued if resource is busy)
/// let transaction = handler.submit(.home)
///
/// // Subscribe to transaction results
/// transaction.resultPublisher
///     .sink { result in
///         switch result {
///         case .completed(let id, let response):
///             print("Command \(id) completed: \(response ?? "no response")")
///         case .failed(let id, let error):
///             print("Command \(id) failed: \(error)")
///         default: break
///         }
///     }
///     .store(in: &cancellables)
///
/// // Handle inbound transactions (remote-initiated)
/// handler.inboundTransactionHandler = { handler, message in
///     // Parse the message, then respond via the pipe directly
/// }
/// ```
public final class TransactionHandler<Command: TransactionalCommand>: @unchecked Sendable {

    // MARK: - Public Properties

    /// Unique identifier for the resource this handler manages.
    public let resourceID: String

    /// Current state of the managed resource.
    public var resourceState: ResourceState {
        resourceStateSubject.value
    }

    /// Publisher for resource state changes.
    public var resourceStatePublisher: OpenCombine.AnyPublisher<ResourceState, Never> {
        resourceStateSubject.eraseToAnyPublisher()
    }

    /// Default timeout for transactions in seconds.
    public var defaultTimeout: TimeInterval {
        get { lock.lock(); defer { lock.unlock() }; return _defaultTimeout }
        set { lock.lock(); defer { lock.unlock() }; _defaultTimeout = newValue }
    }

    /// Maximum number of concurrent parallel transactions.
    public var maxConcurrentParallel: Int {
        get { lock.lock(); defer { lock.unlock() }; return _maxConcurrentParallel }
        set { lock.lock(); defer { lock.unlock() }; _maxConcurrentParallel = newValue }
    }

    /// Maximum queue depth for serial commands.
    public var maxSerialQueueDepth: Int {
        get { lock.lock(); defer { lock.unlock() }; return _maxSerialQueueDepth }
        set { lock.lock(); defer { lock.unlock() }; _maxSerialQueueDepth = newValue }
    }

    /// Publisher for unsolicited events from the resource.
    ///
    /// Unsolicited events are not associated with any specific transaction.
    /// Subscribe to receive general resource notifications.
    ///
    /// ```swift
    /// handler.unsolicitedEventPublisher
    ///     .filter { $0.code >= 2000 && $0.code < 3000 }
    ///     .sink { event in print("Safety event: \(event)") }
    ///     .store(in: &cancellables)
    /// ```
    public var unsolicitedEventPublisher: OpenCombine.AnyPublisher<TransactionEvent, Never> {
        unsolicitedEventSubject.eraseToAnyPublisher()
    }

    /// Parser for incoming messages from the attached pipe.
    ///
    /// Assign this to route inbound strings to the appropriate transaction process methods:
    /// - `processAcknowledgment(transactionID:)` for acks
    /// - `processResponse(transactionID:response:)` for completions
    /// - `processError(transactionID:message:)` for errors
    /// - `processEvent(_:)` or `processEvent(code:payload:transactionID:)` for events
    ///
    /// If the message does not match any pending transaction, call
    /// `inboundTransactionHandler` (if set) before returning.
    public var messageParser: (@Sendable (_ handler: TransactionHandler<Command>, _ message: String) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _messageParser }
        set { lock.lock(); defer { lock.unlock() }; _messageParser = newValue }
    }

    /// Handler for inbound messages whose transaction ID was not initiated locally.
    ///
    /// When the remote peer initiates a transaction, the message will arrive with an ID
    /// not in the local pending table. Rather than silently dropping it, the
    /// `messageParser` should route unknown-ID messages here.
    ///
    /// Wire this to implement bidirectional transaction support:
    /// ```swift
    /// handler.inboundTransactionHandler = { handler, message in
    ///     // Parse the remote-initiated frame and send a response via the pipe
    /// }
    /// ```
    public var inboundTransactionHandler: (@Sendable (_ handler: TransactionHandler<Command>, _ message: String) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _inboundTransactionHandler }
        set { lock.lock(); defer { lock.unlock() }; _inboundTransactionHandler = newValue }
    }

    // MARK: - Private Properties

    private let resourceStateSubject: CurrentValueSubject<ResourceState, Never>
    private let unsolicitedEventSubject = PassthroughSubject<TransactionEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let lock = NSRecursiveLock()
    private var _defaultTimeout: TimeInterval = 30.0
    private var _maxConcurrentParallel: Int = 10
    private var _maxSerialQueueDepth: Int = 100
    private var _messageParser: (@Sendable (_ handler: TransactionHandler<Command>, _ message: String) -> Void)?
    private var _inboundTransactionHandler: (@Sendable (_ handler: TransactionHandler<Command>, _ message: String) -> Void)?
    private var serialQueueHead: Int = 0
    private var exclusiveQueueHead: Int = 0

    /// Counter for generating unique transaction IDs.
    /// IDs cycle 1–899 to stay within the UR robot protocol range.
    private var nextTransactionID: Int = 1

    private var activeSerialTransaction: Transaction<Command>?
    private var serialQueue: [Transaction<Command>] = []
    private var activeParallelTransactions: [Int: Transaction<Command>] = [:]
    private var activeExclusiveTransaction: Transaction<Command>?
    private var exclusiveQueue: [Transaction<Command>] = []
    private var allActiveTransactions: [Int: Transaction<Command>] = [:]
    private var timeoutTimers: [Int: AnyCancellable] = [:]
    private var pipe: (any MessageDuplex)?

    // MARK: - Initialization

    /// Creates a new transaction handler for the specified resource.
    ///
    /// - Parameters:
    ///   - resourceID: Unique identifier for the resource.
    ///   - initialState: Initial resource state. Defaults to `.disconnected`.
    public init(resourceID: String, initialState: ResourceState = .disconnected) {
        self.resourceID = resourceID
        self.resourceStateSubject = CurrentValueSubject(initialState)
    }

    // MARK: - Pipe Attachment

    /// Attaches a communication pipe for sending and receiving messages.
    ///
    /// The pipe provides the transport layer for command/response communication.
    /// When attached, the pipe's inbound handler is automatically configured to
    /// route messages through `messageParser`.
    public func attachPipe(_ pipe: any MessageDuplex) {
        lock.lock()
        defer { lock.unlock() }

        self.pipe = pipe

        pipe.setStringMessageHandler { [weak self] message in
            guard let self = self else { return }
            let parser = self.messageParser
            parser?(self, message)
        }
    }

    /// Detaches the current communication pipe.
    public func detachPipe() {
        lock.lock()
        defer { lock.unlock() }

        pipe?.setStringMessageHandler(nil)
        pipe = nil
    }

    /// Whether a communication pipe is currently attached.
    public var hasPipe: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pipe != nil
    }

    // MARK: - Submission

    /// Submits a command for transaction.
    ///
    /// The command will be processed according to its concurrency category:
    /// - **Serial**: Queued if another serial command is active; executed one at a time
    /// - **Parallel**: Executed immediately alongside other parallel commands
    /// - **Exclusive**: Queued if another exclusive command is active; independent of serial queue
    ///
    /// Transaction ID resolution (priority order):
    /// 1. Command's `trID` if `>= 0`
    /// 2. Auto-generated unique ID (cycles 1–899)
    ///
    /// Timeout resolution (priority order):
    /// 1. Explicit `timeout` parameter
    /// 2. Command's `timeout` property if defined
    /// 3. Handler's `defaultTimeout`
    ///
    /// - Parameters:
    ///   - command: The command to transact.
    ///   - timeout: Optional timeout override.
    /// - Returns: A `Transaction` for tracking progress and subscribing to results.
    @discardableResult
    public func submit(_ command: Command, timeout: TimeInterval? = nil) -> Transaction<Command> {
        lock.lock()
        defer { lock.unlock() }

        let transactionID: Int
        if command.trID >= 0 {
            transactionID = command.trID
        } else {
            transactionID = nextTransactionID
            nextTransactionID = nextTransactionID >= 899 ? 1 : nextTransactionID + 1
        }

        let resolvedTimeout: TimeInterval
        if let explicitTimeout = timeout {
            resolvedTimeout = explicitTimeout
        } else if let commandTimeout = command.timeout {
            resolvedTimeout = TimeInterval(commandTimeout)
        } else {
            resolvedTimeout = _defaultTimeout
        }

        if allActiveTransactions[transactionID] != nil {
            let failed = Transaction(id: transactionID, command: command, timeout: resolvedTimeout)
            failed.markFailed(error: .duplicateTransactionID(id: transactionID))
            return failed
        }

        let transaction = Transaction(
            id: transactionID,
            command: command,
            timeout: resolvedTimeout
        )

        allActiveTransactions[transactionID] = transaction

        switch command.commandType {
        case .serial:
            handleSerialSubmission(transaction)
        case .parallel:
            handleParallelSubmission(transaction)
        case .exclusive:
            handleExclusiveSubmission(transaction)
        }

        return transaction
    }

    // MARK: - Response Processing

    /// Processes an acknowledgment received from the resource.
    ///
    /// - Parameter transactionID: The ID of the acknowledged transaction.
    public func processAcknowledgment(transactionID: Int) {
        lock.lock()
        defer { lock.unlock() }

        guard let transaction = allActiveTransactions[transactionID] else { return }
        transaction.markAcknowledged()

        if transaction.category == .serial {
            updateResourceState(.busy)
        }
    }

    /// Processes a response received from the resource.
    ///
    /// - Parameters:
    ///   - transactionID: The ID of the completed transaction.
    ///   - response: Optional response data.
    public func processResponse(transactionID: Int, response: String? = nil) {
        lock.lock()
        defer { lock.unlock() }

        guard let transaction = allActiveTransactions[transactionID] else { return }

        cancelTimeout(for: transactionID)
        transaction.markCompleted(response: response)
        cleanupTransaction(transaction)
        processNextInQueue(for: transaction.category)
    }

    /// Processes an error response from the resource.
    ///
    /// - Parameters:
    ///   - transactionID: The ID of the failed transaction.
    ///   - message: Error message from the resource.
    public func processError(transactionID: Int, message: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let transaction = allActiveTransactions[transactionID] else { return }

        cancelTimeout(for: transactionID)
        transaction.markFailed(error: .resourceError(message: message))
        cleanupTransaction(transaction)
        processNextInQueue(for: transaction.category)
    }

    /// Processes an event received from the resource.
    ///
    /// Events are routed based on whether they are solicited or unsolicited:
    /// - **Solicited** (with `transactionID`): Routed to the specific transaction's `eventPublisher`
    /// - **Unsolicited** (no `transactionID`): Emitted on `unsolicitedEventPublisher`
    public func processEvent(_ event: TransactionEvent) {
        lock.lock()
        defer { lock.unlock() }

        if let transactionID = event.transactionID,
            let transaction = allActiveTransactions[transactionID]
        {
            transaction.receiveEvent(event)
        } else {
            unsolicitedEventSubject.send(event)
        }
    }

    /// Processes an event using individual parameters.
    ///
    /// Convenience overload that constructs a `TransactionEvent` and routes it.
    public func processEvent(code: Int, payload: String? = nil, transactionID: Int? = nil) {
        let event = TransactionEvent(
            code: code,
            payload: payload,
            transactionID: transactionID,
            resourceID: resourceID
        )
        processEvent(event)
    }

    // MARK: - State Management

    /// Updates the resource state.
    ///
    /// Transitioning to `.error`, `.estop`, or `.disconnected` automatically
    /// cancels all active and queued transactions.
    public func updateResourceState(_ state: ResourceState) {
        lock.lock()
        defer { lock.unlock() }
        resourceStateSubject.send(state)

        if state == .error || state == .estop || state == .disconnected {
            cancelAllActiveTransactions(error: .resourceNotReady(state: state))
        }
    }

    // MARK: - Cancellation

    /// Cancels a specific transaction.
    ///
    /// - Parameter transactionID: The ID of the transaction to cancel.
    public func cancel(transactionID: Int) {
        lock.lock()
        defer { lock.unlock() }

        guard let transaction = allActiveTransactions[transactionID] else { return }

        cancelTimeout(for: transactionID)
        transaction.markCancelled()
        cleanupTransaction(transaction)
        processNextInQueue(for: transaction.category)
    }

    /// Cancels all pending and active transactions.
    public func cancelAll() {
        lock.lock()
        defer { lock.unlock() }

        cancelAllActiveTransactions(error: .cancelled)
    }

    // MARK: - Queue Inspection

    /// Current depth of the serial command queue.
    public var serialQueueCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return serialQueue.count - serialQueueHead
    }

    /// Count of currently active parallel transactions.
    public var activeParallelCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeParallelTransactions.count
    }

    /// Whether the handler is currently executing a serial command.
    public var isSerialBusy: Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeSerialTransaction != nil
    }

    // MARK: - Private Methods

    private func handleSerialSubmission(_ transaction: Transaction<Command>) {
        guard resourceState != .disconnected && resourceState != .error && resourceState != .estop else {
            transaction.markFailed(error: .resourceNotReady(state: resourceState))
            allActiveTransactions.removeValue(forKey: transaction.id)
            return
        }

        if activeSerialTransaction != nil {
            if (serialQueue.count - serialQueueHead) >= _maxSerialQueueDepth {
                transaction.markFailed(
                    error: .categoryConflict(requested: .serial, current: .serial)
                )
                allActiveTransactions.removeValue(forKey: transaction.id)
                return
            }
            serialQueue.append(transaction)
            transaction.markQueued(position: serialQueue.count - serialQueueHead - 1)
        } else {
            executeSerial(transaction)
        }
    }

    private func handleParallelSubmission(_ transaction: Transaction<Command>) {
        guard resourceState != .disconnected && resourceState != .error && resourceState != .estop else {
            transaction.markFailed(error: .resourceNotReady(state: resourceState))
            allActiveTransactions.removeValue(forKey: transaction.id)
            return
        }

        if activeParallelTransactions.count >= _maxConcurrentParallel {
            transaction.markFailed(
                error: .categoryConflict(requested: .parallel, current: .parallel)
            )
            allActiveTransactions.removeValue(forKey: transaction.id)
            return
        }

        executeParallel(transaction)
    }

    private func handleExclusiveSubmission(_ transaction: Transaction<Command>) {
        guard resourceState != .disconnected && resourceState != .error && resourceState != .estop else {
            transaction.markFailed(error: .resourceNotReady(state: resourceState))
            allActiveTransactions.removeValue(forKey: transaction.id)
            return
        }

        if activeExclusiveTransaction != nil {
            exclusiveQueue.append(transaction)
            transaction.markQueued(position: exclusiveQueue.count - exclusiveQueueHead - 1)
        } else {
            executeExclusive(transaction)
        }
    }

    private func executeSerial(_ transaction: Transaction<Command>) {
        activeSerialTransaction = transaction
        sendToResource(transaction)
    }

    private func executeParallel(_ transaction: Transaction<Command>) {
        activeParallelTransactions[transaction.id] = transaction
        sendToResource(transaction)
    }

    private func executeExclusive(_ transaction: Transaction<Command>) {
        activeExclusiveTransaction = transaction
        sendToResource(transaction)
    }

    private func sendToResource(_ transaction: Transaction<Command>) {
        transaction.markSent()
        startTimeout(for: transaction)

        let serialized = transaction.command.serialize(transactionID: String(transaction.id))
        pipe?.send(to: nil, serialized, 0, false)
    }

    private func startTimeout(for transaction: Transaction<Command>) {
        let transactionID = transaction.id
        let timeout = transaction.timeout

        let workItem = DispatchWorkItem { [weak self] in
            self?.handleTimeout(transactionID: transactionID)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: workItem)
        timeoutTimers[transactionID] = AnyCancellable { workItem.cancel() }
    }

    private func cancelTimeout(for transactionID: Int) {
        timeoutTimers[transactionID]?.cancel()
        timeoutTimers.removeValue(forKey: transactionID)
    }

    private func handleTimeout(transactionID: Int) {
        lock.lock()
        defer { lock.unlock() }

        cancelTimeout(for: transactionID)

        guard let transaction = allActiveTransactions[transactionID],
            !transaction.isTerminal
        else { return }

        transaction.markTimedOut()
        cleanupTransaction(transaction)
        processNextInQueue(for: transaction.category)
    }

    private func cleanupTransaction(_ transaction: Transaction<Command>) {
        allActiveTransactions.removeValue(forKey: transaction.id)

        switch transaction.category {
        case .serial:
            if activeSerialTransaction?.id == transaction.id {
                activeSerialTransaction = nil
                if serialQueueHead >= serialQueue.count && resourceState == .busy {
                    updateResourceState(.idle)
                }
            }
        case .parallel:
            activeParallelTransactions.removeValue(forKey: transaction.id)
        case .exclusive:
            if activeExclusiveTransaction?.id == transaction.id {
                activeExclusiveTransaction = nil
            }
        }
    }

    private func dequeueSerial() -> Transaction<Command>? {
        guard serialQueueHead < serialQueue.count else { return nil }
        let item = serialQueue[serialQueueHead]
        serialQueueHead += 1
        if serialQueueHead * 2 >= serialQueue.count {
            serialQueue.removeFirst(serialQueueHead)
            serialQueueHead = 0
        }
        return item
    }

    private func dequeueExclusive() -> Transaction<Command>? {
        guard exclusiveQueueHead < exclusiveQueue.count else { return nil }
        let item = exclusiveQueue[exclusiveQueueHead]
        exclusiveQueueHead += 1
        if exclusiveQueueHead * 2 >= exclusiveQueue.count {
            exclusiveQueue.removeFirst(exclusiveQueueHead)
            exclusiveQueueHead = 0
        }
        return item
    }

    private func processNextInQueue(for category: TransactionConcurrency) {
        switch category {
        case .serial:
            if activeSerialTransaction == nil, let next = dequeueSerial() {
                executeSerial(next)
            }
        case .parallel:
            break  // Parallel commands don't queue
        case .exclusive:
            if activeExclusiveTransaction == nil, let next = dequeueExclusive() {
                executeExclusive(next)
            }
        }
    }

    private func cancelAllActiveTransactions(error: TransactionError) {
        for (id, transaction) in allActiveTransactions where !transaction.isTerminal {
            cancelTimeout(for: id)
            transaction.markFailed(error: error)
        }

        allActiveTransactions.removeAll()
        activeSerialTransaction = nil
        activeParallelTransactions.removeAll()
        activeExclusiveTransaction = nil
        serialQueue.removeAll()
        serialQueueHead = 0
        exclusiveQueue.removeAll()
        exclusiveQueueHead = 0
    }
}
