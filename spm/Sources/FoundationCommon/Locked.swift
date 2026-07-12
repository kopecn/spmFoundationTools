import Foundation

// MARK: - Locked

/// Portable lock-guarded state box.
///
/// `Synchronization.Mutex` requires macOS 15, but this package's floor is
/// macOS 14, so `NSLock` is used instead — it is available on every
/// supported platform (Darwin and Linux/Glibc via `Foundation`).
///
/// The `@unchecked Sendable` conformance is justified: `value` is ONLY
/// reachable through ``withLock(_:)``, which holds `lock` for the duration
/// of the closure. There is no other access path to the stored value.
public final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    /// Creates a new lock-guarded box wrapping the given initial value.
    public init(_ value: Value) {
        self.value = value
    }

    /// Executes `body` with exclusive, mutable access to the guarded value.
    ///
    /// - Parameter body: A closure that may read and/or mutate the guarded
    ///   value. It is invoked while `lock` is held. `body` may throw; the
    ///   lock is still released via `defer` before the error propagates.
    /// - Returns: Whatever `body` returns.
    public func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
