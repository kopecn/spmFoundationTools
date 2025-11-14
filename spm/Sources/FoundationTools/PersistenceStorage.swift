import Foundation

// MARK: - Type-Safe Persistence Key

/// A type-safe key for storing and retrieving values from `PersistenceStorage`.
/// - Parameters:
///   - T: The value type, which must conform to `Codable` and `Sendable`.
/// Example Usage: 
/// /// Extension point for defining persistence keys
/// Other modules can extend this to add their own keys
///     ```
///     extension PersistenceKey where T == String {
///         public static let ipAddress = PersistenceKey(name: "ipAddress", defaultValue: "localhost")
///     }
///     ```
/// with usage:
///     ```
///     Task {
///         await PersistenceStorage.shared.save(ipAddress, for: .ipAddress)
///     }
///     ```
public struct PersistenceKey<T: Codable & Sendable>: Sendable {
    /// The unique string identifier for this key.
    public let name: String
    /// The default value to return if no value is stored.
    public let defaultValue: T

    /// Creates a new type-safe persistence key.
    /// - Parameters:
    ///   - name: The unique string identifier for this key.
    ///   - defaultValue: The default value to use if no value is stored.
    public init(name: String, defaultValue: T) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

// MARK: - Persistence Storage Actor

/// An actor that provides thread-safe, type-safe persistent storage with in-memory caching.
/// 
/// - On macOS: Uses `UserDefaults` for persistence.
/// - On Linux: Uses a JSON file in the user's home directory.
/// 
/// Use the shared singleton instance `PersistenceStorage.shared` to access storage.
public actor PersistenceStorage {

    // MARK: - Singleton

    /// The shared singleton instance of `PersistenceStorage`.
    public static let shared = PersistenceStorage()

    // MARK: - Configuration

    /// The filename used for Linux file-based storage.
    private static let filename = ".sensible_ur_touch_config.json"
    /// The key used to track all stored keys in UserDefaults.
    private static let allKeysStorageKey = "_PersistenceStorage_AllKeys"

    // MARK: - In-Memory Cache

    /// Internal cache for fast access to stored values.
    private var cache: [String: Any] = [:]
    /// Tracks if the cache has unsaved changes.
    private var isDirty = false
    /// Set of all keys that have been stored.
    private var allStoredKeys: Set<String> = []

    // MARK: - Initialization

    /// Initializes the persistence storage and loads existing data.
    /// Use the shared singleton instance instead of calling this directly.
    private init() {
        #if os(macOS)
        // Load the set of all stored keys from UserDefaults.
        if let keysData = UserDefaults.standard.data(forKey: Self.allKeysStorageKey),
           let keys = try? JSONDecoder().decode(Set<String>.self, from: keysData) {
            self.allStoredKeys = keys
        }
        #else
        // On Linux, load the entire JSON file into cache on init.
        self.cache = Self.loadLinuxStorageSync()
        #endif
    }

    // MARK: - Type-Safe API

    /// Saves a value for a type-safe key.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The type-safe key to associate with the value.
    public func save<T: Codable & Sendable>(_ value: T, for key: PersistenceKey<T>) {
        cache[key.name] = value
        allStoredKeys.insert(key.name)
        isDirty = true
        persistCache()
    }

    /// Loads a value for a type-safe key.
    /// - Parameter key: The type-safe key to retrieve.
    /// - Returns: The stored value if available, otherwise the key's default value.
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

    /// Removes a value for a type-safe key.
    /// - Parameter key: The type-safe key to remove.
    public func remove<T: Codable & Sendable>(for key: PersistenceKey<T>) {
        cache.removeValue(forKey: key.name)
        allStoredKeys.remove(key.name)

        #if os(macOS)
        // Also remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: key.name)
        // Update the stored keys set
        isDirty = true
        persistCache()
        #else
        isDirty = true
        persistCache()
        #endif
    }

    /// Clears all cached and persisted data.
    /// Removes all stored values and keys from both memory and persistent storage.
    public func clearAll() {
        #if os(macOS)
        // Remove all stored keys from UserDefaults (not just cached ones)
        for key in allStoredKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        // Also remove the keys tracking entry
        UserDefaults.standard.removeObject(forKey: Self.allKeysStorageKey)
        cache.removeAll()
        allStoredKeys.removeAll()
        #else
        cache.removeAll()
        isDirty = true
        persistCache()
        #endif
    }

    // MARK: - Private Persistence Implementation

    /// Persists the cache to disk if there are unsaved changes.
    private func persistCache() {
        guard isDirty else { return }

        #if os(macOS)
        // Save each cached value to UserDefaults
        for (key, value) in cache {
            saveToUserDefaultsAny(value, forKey: key)
        }
        // Save the set of all stored keys
        if let keysData = try? JSONEncoder().encode(allStoredKeys) {
            UserDefaults.standard.set(keysData, forKey: Self.allKeysStorageKey)
        }
        #else
        // Save entire cache to JSON file
        saveLinuxStorage(cache)
        #endif

        isDirty = false
    }

    /// Loads a value from persistent storage for a given key.
    /// - Parameter key: The string key to retrieve.
    /// - Returns: The decoded value if available, otherwise nil.
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
    /// Saves any value to UserDefaults using JSON encoding.
    private func saveToUserDefaultsAny(_ value: Any, forKey key: String) {
        // Try to encode using AnyEncodable
        if let encoded = try? JSONEncoder().encode(AnyEncodable(value)) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    /// Loads a Codable value from UserDefaults.
    private func loadFromUserDefaults<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }

    /// Helper for encoding Any values to JSON.
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
    /// Gets the file URL for Linux storage.
    private static func getFileURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(filename)
    }

    /// Loads the Linux storage file synchronously into the cache.
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

    /// Saves the cache to the Linux storage file.
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

    /// Helper for encoding Any values to JSON.
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
