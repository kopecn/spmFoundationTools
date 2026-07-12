import Foundation
import Testing
import XCTest

@testable import FoundationTools

// MARK: - Test Helpers

private actor ReceivedMessage {
    private var value: String?

    func set(_ message: String) {
        value = message
    }

    func get() -> String? {
        value
    }
}

// MARK: - Tests

final class NamedPipeChannelTests: XCTestCase {

    // MARK: - Properties

    private var channel: NamedPipeChannel?

    // MARK: - Setup

    override func tearDown() async throws {
        channel?.close()
        channel = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationCreatesChannel() throws {
        let channel = try NamedPipeChannel(name: "test_init", queueStrategy: .fifo)
        XCTAssertEqual(channel.name, "test_init")
        XCTAssertEqual(channel.queueStrategy, .fifo)
        self.channel = channel
    }

    func testInitializationWithDifferentQueueStrategies() throws {
        let fifoChannel = try NamedPipeChannel(name: "test_fifo", queueStrategy: .fifo)
        let lifoChannel = try NamedPipeChannel(name: "test_lifo", queueStrategy: .lifo)
        let roundRobinChannel = try NamedPipeChannel(name: "test_rr", queueStrategy: .roundRobin)

        XCTAssertEqual(fifoChannel.queueStrategy, .fifo)
        XCTAssertEqual(lifoChannel.queueStrategy, .lifo)
        XCTAssertEqual(roundRobinChannel.queueStrategy, .roundRobin)

        // Clean up
        fifoChannel.close()
        lifoChannel.close()
        roundRobinChannel.close()
    }

    func testPipePathsAreCorrect() throws {
        let channel = try NamedPipeChannel(name: "test_paths", queueStrategy: .fifo)
        self.channel = channel

        let tempDir = FileManager.default.temporaryDirectory.path
        XCTAssertEqual(channel.inboundPipePath, "\(tempDir)/test_paths_in")
        XCTAssertEqual(channel.outboundPipePath, "\(tempDir)/test_paths_out")
    }

    func testPipeFilesAreCreated() throws {
        let channel = try NamedPipeChannel(name: "test_files", queueStrategy: .fifo)
        self.channel = channel

        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: channel.inboundPipePath))
        XCTAssertTrue(fileManager.fileExists(atPath: channel.outboundPipePath))
    }

    func testPipeFilesAreRemovedOnDeinit() throws {
        var tempChannel: NamedPipeChannel? = try NamedPipeChannel(name: "test_cleanup", queueStrategy: .fifo)
        let inPath = tempChannel!.inboundPipePath
        let outPath = tempChannel!.outboundPipePath

        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: inPath))
        XCTAssertTrue(fileManager.fileExists(atPath: outPath))

        // Release the channel
        tempChannel = nil

        // Pipes should be removed
        XCTAssertFalse(fileManager.fileExists(atPath: inPath))
        XCTAssertFalse(fileManager.fileExists(atPath: outPath))
    }

    // MARK: - Queue Strategy Tests

    func testQueueStrategyEnum() {
        XCTAssertNotEqual(QueueStrategy.fifo, QueueStrategy.lifo)
        XCTAssertNotEqual(QueueStrategy.lifo, QueueStrategy.roundRobin)
        XCTAssertNotEqual(QueueStrategy.fifo, QueueStrategy.roundRobin)
    }

    // MARK: - Send Tests (Disconnected with Queue)

    func testSendWhileDisconnectedWithQueueEnabled() throws {
        let channel = try NamedPipeChannel(name: "test_queue_send", queueStrategy: .fifo)
        self.channel = channel

        // Should return true because queueIfDisconnected is true
        let result = channel.send(to: nil, "Test message", 0, true)
        XCTAssertTrue(result)
    }

    func testSendWhileDisconnectedWithQueueDisabled() throws {
        let channel = try NamedPipeChannel(name: "test_no_queue_send", queueStrategy: .fifo)
        self.channel = channel

        // Should return false because queueIfDisconnected is false
        let result = channel.send(to: nil, "Test message", 0, false)
        XCTAssertFalse(result)
    }

    func testSendDataWhileDisconnected() throws {
        let channel = try NamedPipeChannel(name: "test_data_send", queueStrategy: .fifo)
        self.channel = channel

        let data = "Test data".data(using: .utf8)!

        // With queue enabled
        let result = channel.send(to: nil, data, 0, true)
        XCTAssertTrue(result)

        // Without queue
        let result2 = channel.send(to: nil, data, 0, false)
        XCTAssertFalse(result2)
    }

    func testSendMultipleMessagesQueued() throws {
        let channel = try NamedPipeChannel(name: "test_multi_queue", queueStrategy: .fifo)
        self.channel = channel

        // Queue multiple messages
        for i in 0..<10 {
            let result = channel.send(to: nil, "Message \(i)", 0, true)
            XCTAssertTrue(result)
        }
    }

    func testSendWithPriority() throws {
        let channel = try NamedPipeChannel(name: "test_priority", queueStrategy: .fifo)
        self.channel = channel

        // Queue messages with different priorities
        let result1 = channel.send(to: nil, "Low priority", 0, true)
        let result2 = channel.send(to: nil, "High priority", 10, true)
        let result3 = channel.send(to: nil, "Medium priority", 5, true)

        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
        XCTAssertTrue(result3)
    }

    // MARK: - Message Handler Tests

    func testSetDataMessageHandler() throws {
        let channel = try NamedPipeChannel(name: "test_data_handler", queueStrategy: .fifo)
        self.channel = channel

        // Setting the handler should not crash
        channel.setDataMessageHandler { _ in }

        // Setting to nil should also work
        channel.setDataMessageHandler(nil)

        // Setting again should work
        channel.setDataMessageHandler { _ in }
    }

    func testSetStringMessageHandler() throws {
        let channel = try NamedPipeChannel(name: "test_string_handler", queueStrategy: .fifo)
        self.channel = channel

        let expectation = XCTestExpectation(description: "Handler should be set")
        expectation.isInverted = true  // We don't expect it to be called since we're not sending

        channel.setStringMessageHandler { message in
            expectation.fulfill()
        }

        // Handler shouldn't be called since no message is sent
        wait(for: [expectation], timeout: 0.1)
    }

    func testClearMessageHandlers() throws {
        let channel = try NamedPipeChannel(name: "test_clear_handlers", queueStrategy: .fifo)
        self.channel = channel

        // Set handlers
        channel.setDataMessageHandler { _ in }
        channel.setStringMessageHandler { _ in }

        // Clear handlers
        channel.setDataMessageHandler(nil)
        channel.setStringMessageHandler(nil)

        // No crash should occur
    }

    // MARK: - HandleMessage Tests

    func testHandleMessageCallsStringHandler() async throws {
        let channel = try NamedPipeChannel(name: "test_handle_msg", queueStrategy: .fifo)
        self.channel = channel

        let expectation = XCTestExpectation(description: "String handler called")
        let receivedMessage = ReceivedMessage()

        channel.setStringMessageHandler { message in
            Task { await receivedMessage.set(message) }
            expectation.fulfill()
        }

        // Allow handler to be set
        try await Task.sleep(nanoseconds: 10_000_000)

        await channel.handleMessage("Hello, World!")

        await fulfillment(of: [expectation], timeout: 1.0)
        let message = await receivedMessage.get()
        XCTAssertEqual(message, "Hello, World!")
    }

    // MARK: - Close Tests

    func testCloseIsIdempotent() throws {
        let channel = try NamedPipeChannel(name: "test_close_idempotent", queueStrategy: .fifo)
        self.channel = channel

        // Multiple closes should not crash
        channel.close()
        channel.close()
        channel.close()
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSends() throws {
        let channel = try NamedPipeChannel(name: "test_concurrent_send", queueStrategy: .fifo)
        self.channel = channel

        let expectation = XCTestExpectation(description: "All sends complete")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            let result = channel.send(to: nil, "Message \(i)", i % 10, true)
            XCTAssertTrue(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testConcurrentHandlerAccess() throws {
        let channel = try NamedPipeChannel(name: "test_concurrent_handler", queueStrategy: .fifo)
        self.channel = channel

        let expectation = XCTestExpectation(description: "All handler operations complete")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            if i % 2 == 0 {
                channel.setStringMessageHandler { _ in }
            } else {
                channel.setDataMessageHandler { _ in }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Error Tests

    func testNamedPipeErrorDescriptions() {
        let createError = NamedPipeError.createFailed(pipe: "/tmp/test", errno: EACCES)
        let openError = NamedPipeError.openFailed(pipe: "/tmp/test", errno: ENOENT)
        let writeError = NamedPipeError.writeFailed(errno: EPIPE)
        let readError = NamedPipeError.readFailed(errno: EIO)

        XCTAssertNotNil(createError.errorDescription)
        XCTAssertNotNil(openError.errorDescription)
        XCTAssertNotNil(writeError.errorDescription)
        XCTAssertNotNil(readError.errorDescription)

        XCTAssertTrue(createError.errorDescription!.contains("/tmp/test"))
        XCTAssertTrue(openError.errorDescription!.contains("/tmp/test"))
    }

    // MARK: - Edge Cases

    func testEmptyStringMessage() throws {
        let channel = try NamedPipeChannel(name: "test_empty_string", queueStrategy: .fifo)
        self.channel = channel

        let result = channel.send(to: nil, "", 0, true)
        XCTAssertTrue(result)
    }

    func testEmptyDataMessage() throws {
        let channel = try NamedPipeChannel(name: "test_empty_data", queueStrategy: .fifo)
        self.channel = channel

        let result = channel.send(to: nil, Data(), 0, true)
        XCTAssertTrue(result)
    }

    func testLargeMessage() throws {
        let channel = try NamedPipeChannel(name: "test_large_msg", queueStrategy: .fifo)
        self.channel = channel

        let largeString = String(repeating: "A", count: 100_000)
        let result = channel.send(to: nil, largeString, 0, true)
        XCTAssertTrue(result)
    }

    func testUnicodeMessage() throws {
        let channel = try NamedPipeChannel(name: "test_unicode", queueStrategy: .fifo)
        self.channel = channel

        let unicodeString = "Hello 👋 世界 🌍 مرحبا"
        let result = channel.send(to: nil, unicodeString, 0, true)
        XCTAssertTrue(result)
    }

    func testSpecialCharactersInMessage() throws {
        let channel = try NamedPipeChannel(name: "test_special_chars", queueStrategy: .fifo)
        self.channel = channel

        let specialString = "Test\n\t\r\0Special\\Characters"
        let result = channel.send(to: nil, specialString, 0, true)
        XCTAssertTrue(result)
    }

    func testNegativePriority() throws {
        let channel = try NamedPipeChannel(name: "test_neg_priority", queueStrategy: .fifo)
        self.channel = channel

        let result = channel.send(to: nil, "Negative priority", -10, true)
        XCTAssertTrue(result)
    }

    func testMaxPriority() throws {
        let channel = try NamedPipeChannel(name: "test_max_priority", queueStrategy: .fifo)
        self.channel = channel

        let result = channel.send(to: nil, "Max priority", Int.max, true)
        XCTAssertTrue(result)
    }

    // MARK: - Multiple Channel Tests

    func testMultipleChannelsIndependent() throws {
        let channel1 = try NamedPipeChannel(name: "test_multi_1", queueStrategy: .fifo)
        let channel2 = try NamedPipeChannel(name: "test_multi_2", queueStrategy: .lifo)

        defer {
            channel1.close()
            channel2.close()
        }

        // Each channel should have its own pipes
        XCTAssertNotEqual(channel1.inboundPipePath, channel2.inboundPipePath)
        XCTAssertNotEqual(channel1.outboundPipePath, channel2.outboundPipePath)

        // Both should work independently
        let result1 = channel1.send(to: nil, "Channel 1", 0, true)
        let result2 = channel2.send(to: nil, "Channel 2", 0, true)

        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
    }

    // MARK: - Sendable Conformance Tests

    func testChannelCanBeSentAcrossTasks() async throws {
        let channel = try NamedPipeChannel(name: "test_sendable", queueStrategy: .fifo)
        self.channel = channel

        let result = await Task {
            channel.send(to: nil, "From another task", 0, true)
        }.value

        XCTAssertTrue(result)
    }

    func testChannelCanBeSharedBetweenActors() async throws {
        let channel = try NamedPipeChannel(name: "test_actor_share", queueStrategy: .fifo)
        self.channel = channel

        actor TestActor {
            let channel: NamedPipeChannel

            init(channel: NamedPipeChannel) {
                self.channel = channel
            }

            func send(message: String) -> Bool {
                channel.send(to: nil, message, 0, true)
            }
        }

        let actor1 = TestActor(channel: channel)
        let actor2 = TestActor(channel: channel)

        let result1 = await actor1.send(message: "From actor 1")
        let result2 = await actor2.send(message: "From actor 2")

        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
    }
}

// MARK: - Race Regression (swift-testing)

/// Regression for F2: `readTask` used to be mutated outside the state lock,
/// racing `open()`'s `startReadLoop()` assignment against `close()`'s
/// cancel/nil. `Locked<SyncState>` (F6/F9) now serializes every access, so
/// this must be deterministic under repeated concurrent open/close and must
/// leave no dangling read task behind.
@Suite("NamedPipeChannel race regression")
struct NamedPipeChannelRaceTests {

    @Test("testF2_concurrentOpenCloseLeavesNoDanglingReadTask")
    func testF2_concurrentOpenCloseLeavesNoDanglingReadTask() async throws {
        let channel = try NamedPipeChannel(
            name: "race_open_close_\(UUID().uuidString)",
            queueStrategy: .fifo
        )
        defer { channel.close() }

        for _ in 0..<100 {
            async let opened: Void = { try? channel.open() }()
            async let closed: Void = channel.close()
            _ = await (opened, closed)
        }

        channel.close()
        #expect(channel.hasActiveReadTask == false)
    }
}
