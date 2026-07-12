---
chunk: 02-locked-and-namedpipe
status: complete
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F2, §F6, §F9
last_updated: 2026-07-11
semver: 0.1.0
author: Nicholas Bergantz
---

# 02 — `Locked<Value>` + NamedPipeChannel race fix

**Deliverable:** a portable synchronization primitive in `FoundationCommon`
(giving the empty target real content — F9 resolved by population), and
`NamedPipeChannel` with ALL its mutable state behind it (F2 race closed,
F6 Apple-only lock removed).

## Files

- Create: `spm/Sources/FoundationCommon/Locked.swift`
  (delete nothing yet — `Placeholder.swift` removal is chunk 06)
- Edit: `spm/Sources/FoundationTools/NamedPipeChannel.swift`
- Create: `spm/Tests/FoundationCommonTests/LockedTests.swift`
- Edit/Create: `spm/Tests/FoundationToolsTests/NamedPipeChannelTests.swift`
  (add the race regression)

## Recipe

`Synchronization.Mutex` needs macOS 15 (floor is 14) — use NSLock:

```swift
/// Portable lock-guarded state box. The @unchecked Sendable is justified:
/// `value` is ONLY reachable through `withLock`, which holds `lock`.
public final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    public init(_ value: Value) { self.value = value }

    public func withLock<R>(_ body: (inout Value) -> R) -> R {
        lock.lock(); defer { lock.unlock() }
        return body(&value)
    }
}
```

**Contract correction (see Resolution notes):** `withLock` must be
`rethrows` over a throwing closure — `NamedPipeChannel.open()` already
calls `try state.withLock { ... throw ... }` to report a pipe-open failure
from inside the locked region, which the non-throwing signature above
cannot support:

```swift
public func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    lock.lock(); defer { lock.unlock() }
    return try body(&value)
}
```

In `NamedPipeChannel`: move `readTask: Task<Void, Never>?` INTO `SyncState`
(NamedPipeChannel.swift:76 → into the struct at :45), replace
`OSAllocatedUnfairLock<SyncState>` with `Locked<SyncState>`, and route the
`:136-137` cancel and `:309` assignment through `withLock`. `Task` handles
are `Sendable`, so `SyncState` stays `Sendable`. The class keeps
`@unchecked Sendable` but now every stored `var` is inside `Locked` — state
outside it must be `let`.

## TDD steps

1. Failing race regression (swift-testing): 100 iterations of
   `async let a = channel.connect(); async let b = channel.disconnect()`
   under TSan-friendly structure — with the old code this is racy on
   `readTask`; after the fix it must be deterministic and leak no running
   task (assert `state.readTask == nil` after disconnect).
2. `LockedTests`: 10k concurrent increments across a TaskGroup total
   exactly 10k.
3. Implement; `make build test` green (run tests with
   `-Xswiftc -sanitize=thread` locally at least once and note the result).

## Acceptance criteria

- [x] `grep -n "OSAllocatedUnfairLock" spm/Sources/` → no hits
- [x] `grep -n "private var" spm/Sources/FoundationTools/NamedPipeChannel.swift` → no hits (all mutable state in `Locked`)
- [x] Locked concurrent-increment test passes; race regression passes
- [x] `make build test` passes

## Out of scope

`Placeholder.swift` deletion and depermaid (chunk 06); converting the class
to an actor (API-breaking — record as a future consideration in completion
notes); PersistenceStorage.

## Resolution notes

- **`Locked.withLock` is `rethrows`, not the recipe's plain signature.**
  `NamedPipeChannel.open()` (pre-existing code, unchanged in this chunk)
  calls `try state.withLock { state in ... throw NamedPipeError... }` to
  report a pipe-open failure from inside the locked region. The recipe's
  literal `(inout Value) -> R` closure type cannot express that, so
  `withLock` was implemented as
  `withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R` — a
  strict superset (every non-throwing call site still compiles unchanged).
  This is the contract correction the task instructions anticipated;
  recorded in the Recipe section above and reflected in this bump to
  `semver: 0.1.0`.
- **Race regression test uses `open()`/`close()`, not `connect()`/
  `disconnect()`.** The recipe's TDD step 1 names `channel.connect()` /
  `channel.disconnect()`, but `NamedPipeChannel`'s actual connection-
  management API is `open()` / `close()` — there are no `connect`/
  `disconnect` methods on this type. The test
  (`NamedPipeChannelTests.swift`, `NamedPipeChannelRaceTests` suite,
  `testF2_concurrentOpenCloseLeavesNoDanglingReadTask`) races `open()`
  against `close()` 100 times instead. This is a naming correction only —
  no behavior or contract changed, so no separate semver note beyond the
  one above.
- **`state.readTask == nil` isn't reachable from the test file as
  literally specified** — `state` and `SyncState` are `private` to
  `NamedPipeChannel`, and Swift's `private` is file-scoped even under
  `@testable import`. Added an `internal` (not `private`) computed
  property `hasActiveReadTask` on `NamedPipeChannel` for exactly this
  assertion; it is not part of the public API (module-internal only,
  reached from the test target via `@testable import`).
- **TSan run:** `swift build -Xswiftc -sanitize=thread` compiles clean
  (confirms `Locked`/`NamedPipeChannel` are TSan-instrumentable with no
  static issues). Actually *executing* the TSan-instrumented
  `FoundationToolsPackageTests.xctest` failed in this sandboxed
  environment with `Sanitizer load violates platform policy`
  (`libclang_rt.tsan_osx_dynamic.dylib` is rejected by the local
  code-signing policy) — an environment/OS restriction, not a defect in
  this change. Recommend re-running
  `swift test --filter NamedPipeChannel -Xswiftc -sanitize=thread` on an
  unsandboxed machine or in CI (chunk 08, linux-verification, is a
  reasonable place to pick this up).
- **Scope guard:** `make format` reformatted ~23 files outside this
  chunk's list (pre-existing formatting drift in `FoundationTypes`,
  `FoundationInterfaces`, `FoundationTransactions`, and their tests). All
  were restored to their committed state via
  `git show HEAD:<path> > <path>`; only `Locked.swift`, `LockedTests.swift`,
  `NamedPipeChannel.swift`, and `NamedPipeChannelTests.swift` remain in the
  diff (`NamedPipeChannel.swift` itself needed no reformatting — it was
  already `swift-format`-clean).
- **Untouched, as instructed:** `Placeholder.swift` (chunk 06), the
  modified `makefile` and untracked `.github/` (pre-existing unrelated
  work), and chunk 01's `SinCos.swift`/`Complex.swift`/`Position.swift`/
  `Quaternion.swift`.
