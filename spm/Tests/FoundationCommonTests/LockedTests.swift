import Testing

@testable import FoundationCommon

// MARK: - Locked Concurrency

@Suite("Locked")
struct LockedTests {

    @Test("testF9_concurrentIncrementsTotalExactly")
    func testF9_concurrentIncrementsTotalExactly() async {
        let counter = Locked(0)
        let iterations = 10_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    counter.withLock { $0 += 1 }
                }
            }
        }

        #expect(counter.withLock { $0 } == iterations)
    }

    @Test("testF9_withLockPropagatesThrownError")
    func testF9_withLockPropagatesThrownError() {
        struct Marker: Error {}
        let box = Locked(0)

        #expect(throws: Marker.self) {
            try box.withLock { _ in
                throw Marker()
            }
        }

        // The lock must be released even after a thrown error — a second
        // call should not deadlock.
        box.withLock { $0 = 42 }
        #expect(box.withLock { $0 } == 42)
    }
}
