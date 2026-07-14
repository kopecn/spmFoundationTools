import Foundation
import Logging
import Testing
import XCTest

@testable import FoundationTools

final class PersistenceStorageTests: XCTestCase {

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        // Clear all data before each test to ensure clean state
        await PersistenceStorage.shared.clearAll()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await PersistenceStorage.shared.clearAll()
        try await super.tearDown()
    }

    // MARK: - PersistenceKey Tests

    func testPersistenceKeyInitialization() {
        let key = PersistenceKey(name: "test.key", defaultValue: "default")
        XCTAssertEqual(key.name, "test.key")
        XCTAssertEqual(key.defaultValue, "default")
    }

    func testPersistenceKeyWithDifferentTypes() {
        let stringKey = PersistenceKey(name: "string.key", defaultValue: "text")
        let intKey = PersistenceKey(name: "int.key", defaultValue: 42)
        let doubleKey = PersistenceKey(name: "double.key", defaultValue: 3.14)
        let floatKey = PersistenceKey(name: "float.key", defaultValue: Float(2.71))
        let boolKey = PersistenceKey(name: "bool.key", defaultValue: true)

        XCTAssertEqual(stringKey.defaultValue, "text")
        XCTAssertEqual(intKey.defaultValue, 42)
        XCTAssertEqual(doubleKey.defaultValue, 3.14)
        XCTAssertEqual(floatKey.defaultValue, Float(2.71))
        XCTAssertEqual(boolKey.defaultValue, true)
    }

    // MARK: - Save and Load Tests

    func testSaveAndLoadString() async {
        let key = PersistenceKey(name: "test.string", defaultValue: "default")

        await PersistenceStorage.shared.save("Hello, World!", for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, "Hello, World!")
    }

    func testSaveAndLoadInt() async {
        let key = PersistenceKey(name: "test.int", defaultValue: 0)

        await PersistenceStorage.shared.save(12345, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, 12345)
    }

    func testSaveAndLoadDouble() async {
        let key = PersistenceKey(name: "test.double", defaultValue: 0.0)

        await PersistenceStorage.shared.save(3.14159, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, 3.14159, accuracy: 0.00001)
    }

    func testSaveAndLoadFloat() async {
        let key = PersistenceKey(name: "test.float", defaultValue: Float(0.0))

        await PersistenceStorage.shared.save(Float(3.14159), for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, Float(3.14159), accuracy: 0.00001)
    }

    func testSaveAndLoadBool() async {
        let trueKey = PersistenceKey(name: "test.bool.true", defaultValue: false)
        let falseKey = PersistenceKey(name: "test.bool.false", defaultValue: true)

        await PersistenceStorage.shared.save(true, for: trueKey)
        await PersistenceStorage.shared.save(false, for: falseKey)

        let loadedTrue = await PersistenceStorage.shared.load(for: trueKey)
        let loadedFalse = await PersistenceStorage.shared.load(for: falseKey)

        XCTAssertTrue(loadedTrue)
        XCTAssertFalse(loadedFalse)
    }

    func testSaveAndLoadNegativeNumbers() async {
        let intKey = PersistenceKey(name: "test.negative.int", defaultValue: 0)
        let doubleKey = PersistenceKey(name: "test.negative.double", defaultValue: 0.0)
        let floatKey = PersistenceKey(name: "test.negative.float", defaultValue: Float(0.0))

        await PersistenceStorage.shared.save(-42, for: intKey)
        await PersistenceStorage.shared.save(-3.14, for: doubleKey)
        await PersistenceStorage.shared.save(Float(-3.14), for: floatKey)

        let loadedInt = await PersistenceStorage.shared.load(for: intKey)
        let loadedDouble = await PersistenceStorage.shared.load(for: doubleKey)
        let loadedFloat = await PersistenceStorage.shared.load(for: floatKey)

        XCTAssertEqual(loadedInt, -42)
        XCTAssertEqual(loadedDouble, -3.14, accuracy: 0.01)
        XCTAssertEqual(loadedFloat, Float(-3.14), accuracy: 0.01)
    }

    // MARK: - Default Value Tests

    func testLoadNonExistentKeyReturnsDefault() async {
        let key = PersistenceKey(name: "non.existent.key", defaultValue: "default value")

        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, "default value")
    }

    func testDefaultValueNotSaved() async {
        let key = PersistenceKey(name: "test.default", defaultValue: "default")

        // Load without saving - should get default
        let loaded = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(loaded, "default")

        // Now save a different value
        await PersistenceStorage.shared.save("custom", for: key)
        let loadedCustom = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(loadedCustom, "custom")
    }

    // MARK: - Update Tests

    func testUpdateExistingValue() async {
        let key = PersistenceKey(name: "test.update", defaultValue: 0)

        await PersistenceStorage.shared.save(10, for: key)
        let first = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(first, 10)

        await PersistenceStorage.shared.save(20, for: key)
        let second = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(second, 20)

        await PersistenceStorage.shared.save(30, for: key)
        let third = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(third, 30)
    }

    // MARK: - Remove Tests

    func testRemoveValue() async {
        let key = PersistenceKey(name: "test.remove", defaultValue: "default")

        // Save a value
        await PersistenceStorage.shared.save("saved", for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(loaded, "saved")

        // Remove the value
        await PersistenceStorage.shared.remove(for: key)
        let loadedAfterRemove = await PersistenceStorage.shared.load(for: key)

        // Should return default value after removal
        XCTAssertEqual(loadedAfterRemove, "default")
    }

    func testRemoveNonExistentKey() async {
        let key = PersistenceKey(name: "test.nonexistent", defaultValue: 0)

        // Removing non-existent key should not crash
        await PersistenceStorage.shared.remove(for: key)

        // Should still return default value
        let loaded = await PersistenceStorage.shared.load(for: key)
        XCTAssertEqual(loaded, 0)
    }

    // MARK: - Clear All Tests

    func testClearAll() async {
        let key1 = PersistenceKey(name: "test.clear.1", defaultValue: "default1")
        let key2 = PersistenceKey(name: "test.clear.2", defaultValue: 0)
        let key3 = PersistenceKey(name: "test.clear.3", defaultValue: false)

        // Save multiple values
        await PersistenceStorage.shared.save("value1", for: key1)
        await PersistenceStorage.shared.save(42, for: key2)
        await PersistenceStorage.shared.save(true, for: key3)

        // Verify they're saved
        let loaded1 = await PersistenceStorage.shared.load(for: key1)
        let loaded2 = await PersistenceStorage.shared.load(for: key2)
        let loaded3 = await PersistenceStorage.shared.load(for: key3)
        XCTAssertEqual(loaded1, "value1")
        XCTAssertEqual(loaded2, 42)
        XCTAssertTrue(loaded3)

        // Clear all
        await PersistenceStorage.shared.clearAll()

        // Verify all return default values
        let loadedAfterClear1 = await PersistenceStorage.shared.load(for: key1)
        let loadedAfterClear2 = await PersistenceStorage.shared.load(for: key2)
        let loadedAfterClear3 = await PersistenceStorage.shared.load(for: key3)
        XCTAssertEqual(loadedAfterClear1, "default1")
        XCTAssertEqual(loadedAfterClear2, 0)
        XCTAssertFalse(loadedAfterClear3)
    }

    // MARK: - Custom Codable Type Tests

    func testCustomCodableType() async {
        struct Person: Codable, Sendable, Equatable {
            let name: String
            let age: Int
            let isActive: Bool
        }

        let defaultPerson = Person(name: "Unknown", age: 0, isActive: false)
        let key = PersistenceKey(name: "test.person", defaultValue: defaultPerson)

        let testPerson = Person(name: "Alice", age: 30, isActive: true)
        await PersistenceStorage.shared.save(testPerson, for: key)

        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded.name, "Alice")
        XCTAssertEqual(loaded.age, 30)
        XCTAssertTrue(loaded.isActive)
    }

    func testCustomCodableTypeWithNestedStructures() async {
        struct Address: Codable, Sendable, Equatable {
            let street: String
            let city: String
        }

        struct User: Codable, Sendable, Equatable {
            let name: String
            let address: Address
        }

        let defaultUser = User(
            name: "Default",
            address: Address(street: "None", city: "None")
        )
        let key = PersistenceKey(name: "test.user", defaultValue: defaultUser)

        let testUser = User(
            name: "Bob",
            address: Address(street: "123 Main St", city: "Springfield")
        )

        await PersistenceStorage.shared.save(testUser, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded.name, "Bob")
        XCTAssertEqual(loaded.address.street, "123 Main St")
        XCTAssertEqual(loaded.address.city, "Springfield")
    }

    func testArrayOfCodableValues() async {
        let key = PersistenceKey(name: "test.array", defaultValue: [String]())

        let testArray = ["apple", "banana", "cherry"]
        await PersistenceStorage.shared.save(testArray, for: key)

        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded, testArray)
    }

    func testDictionaryOfCodableValues() async {
        let key = PersistenceKey(name: "test.dictionary", defaultValue: [String: Int]())

        let testDict = ["one": 1, "two": 2, "three": 3]
        await PersistenceStorage.shared.save(testDict, for: key)

        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded["one"], 1)
        XCTAssertEqual(loaded["two"], 2)
        XCTAssertEqual(loaded["three"], 3)
    }

    // MARK: - Edge Cases

    func testEmptyString() async {
        let key = PersistenceKey(name: "test.empty.string", defaultValue: "default")

        await PersistenceStorage.shared.save("", for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, "")
    }

    func testZeroValue() async {
        let key = PersistenceKey(name: "test.zero", defaultValue: -1)

        await PersistenceStorage.shared.save(0, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, 0)
    }

    func testVeryLargeNumber() async {
        let key = PersistenceKey(name: "test.large", defaultValue: 0)

        let largeNumber = Int.max
        await PersistenceStorage.shared.save(largeNumber, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, largeNumber)
    }

    func testVerySmallNumber() async {
        let key = PersistenceKey(name: "test.small", defaultValue: 0)

        let smallNumber = Int.min
        await PersistenceStorage.shared.save(smallNumber, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, smallNumber)
    }

    func testLongString() async {
        let key = PersistenceKey(name: "test.long.string", defaultValue: "")

        let longString = String(repeating: "A", count: 10000)
        await PersistenceStorage.shared.save(longString, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded.count, 10000)
        XCTAssertEqual(loaded, longString)
    }

    func testSpecialCharacters() async {
        let key = PersistenceKey(name: "test.special.chars", defaultValue: "")

        let specialString = "Hello! @#$%^&*()_+-={}[]|\\:\";<>?,./~`\n\t"
        await PersistenceStorage.shared.save(specialString, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, specialString)
    }

    func testUnicodeCharacters() async {
        let key = PersistenceKey(name: "test.unicode", defaultValue: "")

        let unicodeString = "Hello 👋 世界 🌍 مرحبا"
        await PersistenceStorage.shared.save(unicodeString, for: key)
        let loaded = await PersistenceStorage.shared.load(for: key)

        XCTAssertEqual(loaded, unicodeString)
    }

    // MARK: - Multiple Keys Tests

    func testMultipleKeysIndependence() async {
        let key1 = PersistenceKey(name: "test.multi.1", defaultValue: "default1")
        let key2 = PersistenceKey(name: "test.multi.2", defaultValue: "default2")
        let key3 = PersistenceKey(name: "test.multi.3", defaultValue: "default3")

        await PersistenceStorage.shared.save("value1", for: key1)
        await PersistenceStorage.shared.save("value2", for: key2)
        await PersistenceStorage.shared.save("value3", for: key3)

        let loaded1 = await PersistenceStorage.shared.load(for: key1)
        let loaded2 = await PersistenceStorage.shared.load(for: key2)
        let loaded3 = await PersistenceStorage.shared.load(for: key3)
        XCTAssertEqual(loaded1, "value1")
        XCTAssertEqual(loaded2, "value2")
        XCTAssertEqual(loaded3, "value3")

        // Modify one key
        await PersistenceStorage.shared.save("modified1", for: key1)

        // Others should remain unchanged
        let modifiedLoaded1 = await PersistenceStorage.shared.load(for: key1)
        let modifiedLoaded2 = await PersistenceStorage.shared.load(for: key2)
        let modifiedLoaded3 = await PersistenceStorage.shared.load(for: key3)
        XCTAssertEqual(modifiedLoaded1, "modified1")
        XCTAssertEqual(modifiedLoaded2, "value2")
        XCTAssertEqual(modifiedLoaded3, "value3")
    }

    func testSameKeyNameDifferentTypes() async {
        // Note: In real usage, using the same key name with different types
        // is not type-safe and should be avoided. This tests the behavior.
        let stringKey = PersistenceKey(name: "test.samename", defaultValue: "default")

        await PersistenceStorage.shared.save("text", for: stringKey)
        let loaded = await PersistenceStorage.shared.load(for: stringKey)

        XCTAssertEqual(loaded, "text")
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSaves() async {
        let key1 = PersistenceKey(name: "test.concurrent.1", defaultValue: 0)
        let key2 = PersistenceKey(name: "test.concurrent.2", defaultValue: 0)
        let key3 = PersistenceKey(name: "test.concurrent.3", defaultValue: 0)

        // Perform concurrent saves
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await PersistenceStorage.shared.save(100, for: key1)
            }
            group.addTask {
                await PersistenceStorage.shared.save(200, for: key2)
            }
            group.addTask {
                await PersistenceStorage.shared.save(300, for: key3)
            }
        }

        // All values should be saved correctly
        let concurrentLoaded1 = await PersistenceStorage.shared.load(for: key1)
        let concurrentLoaded2 = await PersistenceStorage.shared.load(for: key2)
        let concurrentLoaded3 = await PersistenceStorage.shared.load(for: key3)
        XCTAssertEqual(concurrentLoaded1, 100)
        XCTAssertEqual(concurrentLoaded2, 200)
        XCTAssertEqual(concurrentLoaded3, 300)
    }

    func testConcurrentLoads() async {
        let key = PersistenceKey(name: "test.concurrent.load", defaultValue: 0)

        await PersistenceStorage.shared.save(42, for: key)

        // Perform concurrent loads
        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await PersistenceStorage.shared.load(for: key)
                }
            }

            for await value in group {
                XCTAssertEqual(value, 42)
            }
        }
    }
}

// MARK: - F1 Log-Capture Test Support

/// A single captured log emission, recorded verbatim for assertions.
private struct CapturedLogEntry {
    let level: Logger.Level
    let message: String
}

/// Lock-guarded sink for captured log entries. Not built on `FoundationCommon`'s
/// `Locked<Value>` to avoid adding a cross-target test dependency for this single
/// use; this is a self-contained equivalent scoped to the test target.
private final class CapturedLogEntrySink: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [CapturedLogEntry] = []

    func append(_ entry: CapturedLogEntry) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(entry)
    }

    /// Returns everything captured so far and clears the sink, so each test starts
    /// from a known-empty state.
    func drain() -> [CapturedLogEntry] {
        lock.lock()
        defer { lock.unlock() }
        let drained = entries
        entries.removeAll()
        return drained
    }
}

/// Minimal `LogHandler` that records every emitted message into
/// `CapturingLogHandler.entries` instead of writing anywhere. Installed once via
/// `LogCapture.installOnce` so `PersistenceStorage`'s internal logger (constructed
/// fresh at each failure site) resolves to this handler.
private struct CapturingLogHandler: LogHandler {
    static let entries = CapturedLogEntrySink()

    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let keys = metadata?["keys"].map { " keys=\($0)" } ?? ""
        Self.entries.append(CapturedLogEntry(level: level, message: "\(message.description)\(keys)"))
    }
}

/// Bootstraps `LoggingSystem` with `CapturingLogHandler` exactly once for the whole
/// test process. Safe here because `PersistenceStorage.logger` is constructed fresh
/// per failure (not cached), and no test in this file triggers a persistence
/// warning/error before this runs (see each `@Test`'s first line).
private enum LogCapture {
    static let installOnce: Void = {
        LoggingSystem.bootstrap { _ in CapturingLogHandler() }
    }()
}

// MARK: - F1 Regression Tests (PersistenceStorage error surfacing)

@Suite("PersistenceStorage F1 error surfacing", .serialized)
struct PersistenceStorageErrorSurfacingTests {

    init() {
        _ = LogCapture.installOnce
    }

    /// A value `PersistenceStorage`'s `AnyEncodable` cannot encode (its switch only
    /// covers String/Int/Float/Double/Bool/Data) — used to force a skipped key.
    private struct Unencodable: Codable, Sendable, Equatable {
        let tag: String
    }

    @Test("testF1_skippedUnencodableValueLogsWarningAndPersistsEncodableKeys")
    func testF1_skippedUnencodableValueLogsWarningAndPersistsEncodableKeys() async throws {
        await PersistenceStorage.shared.clearAll()
        _ = CapturingLogHandler.entries.drain()

        let unencodableKey = PersistenceKey(
            name: "f1.unencodable",
            defaultValue: Unencodable(tag: "default")
        )
        let encodableKey = PersistenceKey(name: "f1.encodable", defaultValue: "default")

        await PersistenceStorage.shared.save(Unencodable(tag: "value"), for: unencodableKey)
        await PersistenceStorage.shared.save("hello", for: encodableKey)

        let entries = CapturingLogHandler.entries.drain()
        let warning = try #require(entries.first { $0.level == .warning })
        #expect(warning.message.contains("f1.unencodable"))

        #if os(macOS)
        // Verify the encodable key really reached persisted storage (UserDefaults),
        // not just the in-memory cache that `load()` would otherwise satisfy from.
        let persisted = try #require(UserDefaults.standard.data(forKey: "f1.encodable"))
        let decoded = try JSONDecoder().decode(String.self, from: persisted)
        #expect(decoded == "hello")
        #else
        // On Linux, confirm the encodable key really reached the on-disk storage
        // file (not just the in-memory cache), by decoding that file directly.
        let onDisk = try Data(contentsOf: PersistenceStorage.getFileURL())
        let encodedStorage = try JSONDecoder().decode([String: String].self, from: onDisk)
        let valueData = try #require(
            encodedStorage["f1.encodable"].flatMap { Data(base64Encoded: $0) }
        )
        let decoded = try JSONDecoder().decode(String.self, from: valueData)
        #expect(decoded == "hello")
        #endif

        await PersistenceStorage.shared.clearAll()
    }

    #if os(macOS)
    @Test("testF1_fullyFailedSaveSurfacesErrorLog")
    func testF1_fullyFailedSaveSurfacesErrorLog() async throws {
        // On macOS the active path is UserDefaults, which has no "unwritable URL"
        // failure mode; the equivalent fully-failed save is every cached value
        // being unencodable, which the design requires to surface at `.error`.
        await PersistenceStorage.shared.clearAll()
        _ = CapturingLogHandler.entries.drain()

        let key = PersistenceKey(name: "f1.allunencodable", defaultValue: Unencodable(tag: "default"))
        await PersistenceStorage.shared.save(Unencodable(tag: "value"), for: key)

        let entries = CapturingLogHandler.entries.drain()
        let errorEntry = try #require(entries.first { $0.level == .error })
        #expect(errorEntry.message.contains("Failed to persist storage"))

        await PersistenceStorage.shared.clearAll()
    }
    #else
    @Test("testF1_unwritableTargetSurfacesErrorLog")
    func testF1_unwritableTargetSurfacesErrorLog() async throws {
        // Linux-only: point HOME at a read-only directory so the atomic file write
        // in `saveLinuxStorage` fails, and confirm the failure is logged at `.error`
        // (never `print`-and-dropped).
        await PersistenceStorage.shared.clearAll()
        _ = CapturingLogHandler.entries.drain()

        let readOnlyDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("f1-readonly-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: readOnlyDir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: readOnlyDir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: readOnlyDir.path)
            try? FileManager.default.removeItem(at: readOnlyDir)
        }

        let previousHome = ProcessInfo.processInfo.environment["HOME"]
        setenv("HOME", readOnlyDir.path, 1)
        defer {
            if let previousHome {
                setenv("HOME", previousHome, 1)
            } else {
                unsetenv("HOME")
            }
        }

        let key = PersistenceKey(name: "f1.unwritable", defaultValue: "default")
        await PersistenceStorage.shared.save("value", for: key)

        let entries = CapturingLogHandler.entries.drain()
        let errorEntry = try #require(entries.first { $0.level == .error })
        #expect(errorEntry.message.contains("Failed to persist storage"))
    }
    #endif
}
