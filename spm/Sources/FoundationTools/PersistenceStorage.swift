import Foundation

// MARK: - Type-Safe Persistence Key

/// A type-safe key for storing and retrieving values from PersistenceStorage
public struct PersistenceKey<T: Codable & Sendable>: Sendable {
    public let name: String
    public let defaultValue: T

    public init(name: String, defaultValue: T) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

// MARK: - Persistence Storage Actor

/// Thread-safe persistence storage with in-memory caching
/// - macOS: Uses UserDefaults
/// - Linux: Uses JSON file in home directory
public actor PersistenceStorage {

    // MARK: - Singleton

    public static let shared = PersistenceStorage()

    // MARK: - Configuration

    private static let filename = ".sensible_ur_touch_config.json"

    // MARK: - In-Memory Cache

    private var cache: [String: Any] = [:]
    private var isDirty = false

    // MARK: - Initialization

    private init() {
        #if !os(macOS)
        // On Linux, load the entire JSON file into cache on init
        self.cache = Self.loadLinuxStorageSync()
        #endif
    }

    // MARK: - Type-Safe API

    /// Save a value for a type-safe key
    public func save<T: Codable & Sendable>(_ value: T, for key: PersistenceKey<T>) {
        cache[key.name] = value
        isDirty = true
        persistCache()
    }

    /// Load a value for a type-safe key
    public func load<T: Codable & Sendable>(for key: PersistenceKey<T>) -> T {
        // Check cache first
        if let cached = cache[key.name] as? T {
            return cached
        }

        // Try to load from persistent storage
        if let loaded: T = loadFromPersistentStorage(forKey: key.name) {
            cache[key.name] = loaded
            return loaded
        }

        // Return default value
        return key.defaultValue
    }

    /// Remove a value for a key
    public func remove<T: Codable & Sendable>(for key: PersistenceKey<T>) {
        cache.removeValue(forKey: key.name)
        isDirty = true
        persistCache()
    }

    /// Clear all cached and persisted data
    public func clearAll() {
        cache.removeAll()
        isDirty = true
        persistCache()
    }

    // MARK: - Private Persistence Implementation

    private func persistCache() {
        guard isDirty else { return }

        #if os(macOS)
        // Save each cached value to UserDefaults
        for (key, value) in cache {
            saveToUserDefaultsAny(value, forKey: key)
        }
        #else
        // Save entire cache to JSON file
        saveLinuxStorage(cache)
        #endif

        isDirty = false
    }

    private func loadFromPersistentStorage<T: Codable>(forKey key: String) -> T? {
        #if os(macOS)
        return loadFromUserDefaults(forKey: key)
        #else
        // Already loaded into cache in init
        return nil
        #endif
    }

    // MARK: - macOS UserDefaults Implementation

    #if os(macOS)
    private func saveToUserDefaultsAny(_ value: Any, forKey key: String) {
        // Try to encode using AnyEncodable
        if let encoded = try? JSONEncoder().encode(AnyEncodable(value)) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func loadFromUserDefaults<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }

    // Helper for encoding Any values
    private struct AnyEncodable: Encodable {
        let value: Any

        init(_ value: Any) {
            self.value = value
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch value {
            case let string as String:
                try container.encode(string)
            case let int as Int:
                try container.encode(int)
            case let double as Double:
                try container.encode(double)
            case let bool as Bool:
                try container.encode(bool)
            case let data as Data:
                try container.encode(data)
            default:
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "Type not supported for encoding"
                    )
                )
            }
        }
    }
    #endif

    // MARK: - Linux File Storage Implementation

    #if !os(macOS)
    private static func getFileURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(filename)
    }

    private static func loadLinuxStorageSync() -> [String: Any] {
        do {
            let fileURL = getFileURL()
            let data = try Data(contentsOf: fileURL)

            // Decode as [String: String] (base64 encoded values)
            let encodedStorage = try JSONDecoder().decode([String: String].self, from: data)

            // Decode each value back to its original type
            var decodedCache: [String: Any] = [:]
            for (key, base64String) in encodedStorage {
                if let valueData = Data(base64Encoded: base64String) {
                    // Store the raw data - will be decoded when accessed with proper type
                    decodedCache[key] = valueData
                }
            }

            return decodedCache
        } catch {
            // File doesn't exist or is invalid, return empty storage
            return [:]
        }
    }

    private func saveLinuxStorage(_ cache: [String: Any]) {
        do {
            var encodedStorage: [String: String] = [:]

            for (key, value) in cache {
                // If already Data, use it directly
                if let data = value as? Data {
                    encodedStorage[key] = data.base64EncodedString()
                }
                // Otherwise, try to encode it
                else if let encoded = try? JSONEncoder().encode(AnyEncodable(value)) {
                    encodedStorage[key] = encoded.base64EncodedString()
                }
            }

            let fileURL = Self.getFileURL()
            let data = try JSONEncoder().encode(encodedStorage)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save storage: \(error)")
        }
    }

    // Helper for encoding Any values
    private struct AnyEncodable: Encodable {
        let value: Any

        init(_ value: Any) {
            self.value = value
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch value {
            case let string as String:
                try container.encode(string)
            case let int as Int:
                try container.encode(int)
            case let double as Double:
                try container.encode(double)
            case let bool as Bool:
                try container.encode(bool)
            case let data as Data:
                try container.encode(data)
            default:
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "Type not supported for encoding"
                    )
                )
            }
        }
    }
    #endif
}
