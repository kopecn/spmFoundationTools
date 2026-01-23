import Foundation
import FoundationInterfaces
import os

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// MARK: - Queue Strategy

/// Defines the ordering strategy for message queue processing.
public enum QueueStrategy: Sendable {
    /// First in, first out ordering.
    case fifo
    /// Last in, first out ordering (stack behavior).
    case lifo
    /// Cycles through destinations in round-robin fashion.
    case roundRobin
}

// MARK: - Named Pipe Channel

/// A bidirectional IPC channel using Unix named pipes (FIFOs).
///
/// Creates two named pipes in `/tmp` for full-duplex communication:
/// - `<name>_in` for receiving messages
/// - `<name>_out` for sending messages
///
/// Conforms to `MessageSendable` and `MessageReceivable` for integration
/// with the messaging protocol system.
///
/// - Note: Named pipes are created in the system temporary directory for
///   cross-platform compatibility (macOS and Linux).
public final class NamedPipeChannel: MessageDuplex, @unchecked Sendable {

    // MARK: - Types

    private struct QueuedMessage: Sendable {
        let data: Data
        let priority: Int
    }

    private struct SyncState: Sendable {
        var messageQueue: [QueuedMessage] = []
        var roundRobinIndex: Int = 0
        var isConnected: Bool = false
        var inboundFileDescriptor: Int32 = -1
        var outboundFileDescriptor: Int32 = -1
        var dataHandler: (@Sendable (Data) -> Void)?
        var stringHandler: (@Sendable (String) -> Void)?
    }

    // MARK: - Properties

    /// The base name for the pipe files.
    public let name: String

    /// The queue ordering strategy.
    public let queueStrategy: QueueStrategy

    /// Path to the inbound pipe.
    public var inboundPipePath: String {
        pipePath(suffix: "_in")
    }

    /// Path to the outbound pipe.
    public var outboundPipePath: String {
        pipePath(suffix: "_out")
    }

    // MARK: - Private State

    private let state: OSAllocatedUnfairLock<SyncState>
    private var readTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a new named pipe channel.
    ///
    /// - Parameters:
    ///   - name: The base name for the pipe files (e.g., "myapp" creates "myapp_in" and "myapp_out").
    ///   - queueStrategy: The ordering strategy for queued messages. Defaults to `.fifo`.
    /// - Throws: An error if the pipes cannot be created.
    public init(name: String, queueStrategy: QueueStrategy = .fifo) throws {
        self.name = name
        self.queueStrategy = queueStrategy
        self.state = OSAllocatedUnfairLock(initialState: SyncState())

        try createPipes()
    }

    deinit {
        closeSync()
        removePipes()
    }

    // MARK: - Connection Management

    /// Opens the pipe channel for communication.
    ///
    /// - Throws: `NamedPipeError` if the pipes cannot be opened.
    public func open() throws {
        try state.withLock { state in
            guard !state.isConnected else { return }

            // Open inbound pipe for reading
            let inFD = openPipe(inboundPipePath, O_RDONLY | O_NONBLOCK)
            guard inFD != -1 else {
                throw NamedPipeError.openFailed(pipe: inboundPipePath, errno: errno)
            }

            // Open outbound pipe for writing
            let outFD = openPipe(outboundPipePath, O_WRONLY | O_NONBLOCK)
            guard outFD != -1 else {
                closePipe(inFD)
                throw NamedPipeError.openFailed(pipe: outboundPipePath, errno: errno)
            }

            state.inboundFileDescriptor = inFD
            state.outboundFileDescriptor = outFD
            state.isConnected = true
        }

        startReadLoop()
        flushQueue()
    }

    /// Closes the pipe channel.
    public func close() {
        closeSync()
    }

    private func closeSync() {
        readTask?.cancel()
        readTask = nil

        state.withLock { state in
            if state.inboundFileDescriptor != -1 {
                closePipe(state.inboundFileDescriptor)
                state.inboundFileDescriptor = -1
            }

            if state.outboundFileDescriptor != -1 {
                closePipe(state.outboundFileDescriptor)
                state.outboundFileDescriptor = -1
            }

            state.isConnected = false
        }
    }

    // MARK: - MessageSendable

    @discardableResult
    public func send(
        to id: (any Identifiable)?,
        _ data: Data,
        _ priority: Int,
        _ queueIfDisconnected: Bool
    ) -> Bool {
        state.withLock { state in
            if state.isConnected {
                return writeData(data, to: state.outboundFileDescriptor)
            } else if queueIfDisconnected {
                enqueue(QueuedMessage(data: data, priority: priority), into: &state)
                return true
            }
            return false
        }
    }

    @discardableResult
    public func send(
        to id: (any Identifiable)?,
        _ message: String,
        _ priority: Int,
        _ queueIfDisconnected: Bool
    ) -> Bool {
        guard let data = message.data(using: .utf8) else {
            return false
        }
        return send(to: id, data, priority, queueIfDisconnected)
    }

    // MARK: - MessageReceivable

    public func setDataMessageHandler(_ handler: (@Sendable (Data) -> Void)?) {
        state.withLock { $0.dataHandler = handler }
    }

    public func setStringMessageHandler(_ handler: (@Sendable (String) -> Void)?) {
        state.withLock { $0.stringHandler = handler }
    }

    public func handleMessage(_ message: String) async {
        let handler = state.withLock { $0.stringHandler }
        handler?(message)
    }

    // MARK: - Private Methods

    private func pipePath(suffix: String) -> String {
        let tempDir = FileManager.default.temporaryDirectory.path
        return "\(tempDir)/\(name)\(suffix)"
    }

    private func createPipes() throws {
        removePipes()

        let inResult = mkfifo(inboundPipePath, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP)
        if inResult != 0 && errno != EEXIST {
            throw NamedPipeError.createFailed(pipe: inboundPipePath, errno: errno)
        }

        let outResult = mkfifo(outboundPipePath, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP)
        if outResult != 0 && errno != EEXIST {
            unlink(inboundPipePath)
            throw NamedPipeError.createFailed(pipe: outboundPipePath, errno: errno)
        }
    }

    private func removePipes() {
        unlink(inboundPipePath)
        unlink(outboundPipePath)
    }

    private func openPipe(_ path: String, _ flags: Int32) -> Int32 {
        #if canImport(Darwin)
        return Darwin.open(path, flags)
        #elseif canImport(Glibc)
        return Glibc.open(path, flags)
        #endif
    }

    private func closePipe(_ fd: Int32) {
        #if canImport(Darwin)
        _ = Darwin.close(fd)
        #elseif canImport(Glibc)
        _ = Glibc.close(fd)
        #endif
    }

    private func readPipe(_ fd: Int32, _ buffer: UnsafeMutablePointer<UInt8>, _ count: Int) -> Int {
        #if canImport(Darwin)
        return Darwin.read(fd, buffer, count)
        #elseif canImport(Glibc)
        return Glibc.read(fd, buffer, count)
        #endif
    }

    private func writePipe(_ fd: Int32, _ buffer: UnsafeRawPointer, _ count: Int) -> Int {
        #if canImport(Darwin)
        return Darwin.write(fd, buffer, count)
        #elseif canImport(Glibc)
        return Glibc.write(fd, buffer, count)
        #endif
    }

    private func writeData(_ data: Data, to fd: Int32) -> Bool {
        guard fd != -1 else { return false }

        return data.withUnsafeBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress else { return false }
            let written = writePipe(fd, baseAddress, buffer.count)
            return written == buffer.count
        }
    }

    private func enqueue(_ message: QueuedMessage, into state: inout SyncState) {
        switch queueStrategy {
        case .fifo:
            let insertIndex = state.messageQueue.firstIndex { $0.priority < message.priority } ?? state.messageQueue.endIndex
            state.messageQueue.insert(message, at: insertIndex)
        case .lifo:
            let insertIndex = state.messageQueue.firstIndex { $0.priority < message.priority } ?? 0
            state.messageQueue.insert(message, at: insertIndex)
        case .roundRobin:
            state.messageQueue.append(message)
        }
    }

    private func dequeue(from state: inout SyncState) -> QueuedMessage? {
        guard !state.messageQueue.isEmpty else { return nil }

        switch queueStrategy {
        case .fifo:
            return state.messageQueue.removeFirst()
        case .lifo:
            return state.messageQueue.removeLast()
        case .roundRobin:
            let index = state.roundRobinIndex % state.messageQueue.count
            state.roundRobinIndex += 1
            return state.messageQueue.remove(at: index)
        }
    }

    private func flushQueue() {
        state.withLock { state in
            while !state.messageQueue.isEmpty {
                guard let message = dequeue(from: &state) else { break }
                _ = writeData(message.data, to: state.outboundFileDescriptor)
            }
        }
    }

    private func startReadLoop() {
        readTask = Task { [weak self] in
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            while !Task.isCancelled {
                guard let self = self else { break }

                let (fd, dataHandler, stringHandler) = self.state.withLock { state in
                    (state.inboundFileDescriptor, state.dataHandler, state.stringHandler)
                }

                guard fd != -1 else { break }

                let bytesRead = self.readPipe(fd, buffer, bufferSize)

                if bytesRead > 0 {
                    let data = Data(bytes: buffer, count: bytesRead)

                    if let handler = dataHandler {
                        handler(data)
                    }

                    if let handler = stringHandler,
                       let string = String(data: data, encoding: .utf8) {
                        handler(string)
                    }
                } else if bytesRead == 0 {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                } else if errno == EAGAIN || errno == EWOULDBLOCK {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                } else {
                    break
                }
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during named pipe operations.
public enum NamedPipeError: Error, Sendable {
    /// Failed to create a named pipe.
    case createFailed(pipe: String, errno: Int32)
    /// Failed to open a named pipe.
    case openFailed(pipe: String, errno: Int32)
    /// Failed to write to the pipe.
    case writeFailed(errno: Int32)
    /// Failed to read from the pipe.
    case readFailed(errno: Int32)
}

extension NamedPipeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .createFailed(let pipe, let errno):
            return "Failed to create pipe '\(pipe)': \(String(cString: strerror(errno)))"
        case .openFailed(let pipe, let errno):
            return "Failed to open pipe '\(pipe)': \(String(cString: strerror(errno)))"
        case .writeFailed(let errno):
            return "Failed to write to pipe: \(String(cString: strerror(errno)))"
        case .readFailed(let errno):
            return "Failed to read from pipe: \(String(cString: strerror(errno)))"
        }
    }
}
