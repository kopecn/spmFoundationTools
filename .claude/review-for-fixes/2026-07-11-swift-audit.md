---
type: audit
name: swift-audit-foundation-tools
purpose: Repo-wide Swift audit — findings ranked by severity with minimal fixes
last_updated: 2026-07-13
semver: 0.7.0
author: Nicholas Bergantz
---

# Swift Audit — spmFoundationTools

Scope: all 5 targets (`FoundationTypes`, `FoundationTools`,
`FoundationInterfaces`, `FoundationTransactions`, `FoundationCommon`),
~8,000 lines. Reviewed against the Swift specs
(`swift.md` + concurrency / error-handling / performance / cross-platform).
Each finding: severity → evidence → minimal fix. The paired audit for the
math package is `spmMathTools/.claude/review-for-fixes/2026-07-11-swift-audit.md`.

## Fix — correctness & error handling

### F1. `PersistenceStorage` swallows save failures with `print` — MAJOR — RESOLVED (chunk 03)
`Sources/FoundationTools/PersistenceStorage.swift:303`:
`catch { print("Failed to save storage: \(error)") }`. A failed persistence
write is an actionable failure reported to stdout and then dropped
(error-handling spec: "never fail silently"; `print` is not logging). Two
levels up (`:294`), `try? JSONEncoder().encode(AnyEncodable(value))` also
silently drops any unencodable value — data loss with no signal.
**Fix:** make the save path `throws` (or return `Result`) and log via
`swift-log` (already a dependency of this target); count/log skipped
unencodable keys instead of silently omitting them. Applied: both
`persistCache()` (macOS/UserDefaults) and `saveLinuxStorage` now throw
`PersistenceStorageError.allValuesUnencodable` when every value fails to
encode, and log skipped keys at `.warning` / any failure at `.error` via
`Logger(label: "FoundationTools.PersistenceStorage")`; `print` removed.

### F2. `NamedPipeChannel.readTask` mutated outside the lock — MAJOR (data race) — RESOLVED (chunk 02)
`Sources/FoundationTools/NamedPipeChannel.swift:36` declares
`@unchecked Sendable` justified by `OSAllocatedUnfairLock<SyncState>` — but
`private var readTask: Task<Void, Never>?` (`:76`) sits **outside**
`SyncState`. `connect`/`disconnect` from two threads race on `:136-137` /
`:309` (concurrency spec: `@unchecked Sendable` requires an *obvious,
complete* synchronization mechanism — this one has a hole).
**Fix:** move `readTask` into the locked `SyncState`, or convert the class
to an `actor` and delete `@unchecked Sendable` entirely. Applied: `readTask`
moved into `SyncState`, guarded by the new `Locked<Value>` primitive; the
actor conversion is deferred (API-breaking, recorded as a future
consideration).

### F3. `TransactionHandler` timeout is unstructured and uncancellable — MAJOR — RESOLVED (chunk 04)
`Sources/FoundationTransactions/TransactionHandler.swift:513`:
`DispatchQueue.global().asyncAfter(deadline:execute:)` schedules the timeout
work item outside structured concurrency — it ignores task cancellation and
outlives the transaction (concurrency spec: prefer structured concurrency;
tasks must cooperate with cancellation).
**Fix:** replace with a child `Task` using `try await Task.sleep(for:)` +
`Task.checkCancellation()`, cancelled when the transaction completes.
**Applied:** `startTimeout(for:)` now stores a `Task<Void, Never>` per
transaction (`timeoutTasks: [Int: Task<Void, Never>]`, replacing
`timeoutTimers: [Int: AnyCancellable]`) that awaits `Task.sleep(for:)` and
calls `handleTimeout` on completion, catching `CancellationError` as a no-op;
`cancelTimeout(for:)` calls `.cancel()` on the stored task. All existing
completion paths (`processResponse`, `processError`, `cancel`,
`cancelAllActiveTransactions`) already routed through `cancelTimeout(for:)`,
so no call sites needed further changes. Regression coverage:
`spm/Tests/FoundationTransactionsTests/TransactionHandlerTests.swift` (new
test target `FoundationTransactionsTests` added to `Package.swift`, since none
existed for this module).

### F4. `NSRecursiveLock` in `TransactionHandler` — MINOR (smell)
`TransactionHandler.swift:140`. Recursive locking usually papers over
re-entrant call paths that should be restructured; combined with
`@unchecked Sendable` (`:53`) the type's thread-safety is unverifiable by
the compiler.
**Fix (when touched next):** restructure so public entry points take the
lock exactly once (plain `NSLock`/`Mutex`), or make the handler an actor.
(Not resolved in chunk 04 — a `// AUDIT F4:` comment now sits at the
declaration, noting the concrete re-entrant path: `cleanupTransaction`,
called while `lock` is held by `processResponse`/`processError`/`cancel`/
`handleTimeout`, calls the public `updateResourceState(_:)`, which re-acquires
`lock`. Full restructure remains deferred alongside the F10 decision.)

## Fix — cross-platform (decide Linux, then act)

The repo's own toolchain choice (kvSIMD instead of Apple `simd`) signals
cross-platform intent, but two Apple-only APIs contradict it
(cross-platform spec: shared modules compile unchanged on Linux). If Linux
is a non-goal, record that in `.claude/CLAUDE.md` and close F5/F6 as
documented decisions instead.

### F5. `__sincos` / `__sincosf` are Darwin libm — breaks Linux — MAJOR* — RESOLVED (chunk 01)
`FoundationTypes/Complex.swift:123,150`, `Position.swift:120-217` (10
sites — the original count of 4 missed the `sphericalISO` initializers at
:186-217), `Quaternion.swift:150-228` (8 sites). **20 sites total**, not 14
as originally counted.
**Fix:** one internal helper
`@usableFromInline func sincos(_ x: Double) -> (sin: Double, cos: Double)`
(+ `Float` overload) with `#if canImport(Darwin)` using `__sincos`/
`__sincosf`, `#else` separate `sin`/`cos` (modern compilers fuse the pair
anyway); all 20 call sites route through it. See
`spm/Sources/FoundationTypes/Support/SinCos.swift`.

### F6. `OSAllocatedUnfairLock` is Apple-only — MAJOR* — RESOLVED (chunk 02)
`FoundationTools/NamedPipeChannel.swift` (state lock). Swift 6's
`Synchronization.Mutex` is the portable, modern equivalent.
**Fix:** `Mutex<SyncState>` (fold together with F2's actor decision — an
actor solves F2 and F6 at once). Applied: `Synchronization.Mutex` requires
macOS 15 (floor is macOS 14), so `Locked<Value>` (`NSLock`-backed, portable
to Linux via Foundation) replaces `OSAllocatedUnfairLock` instead.

## Fix — API & structural

### F7. `@unchecked Sendable` on pure value structs — MAJOR (free win) — RESOLVED (chunk 05)
`FoundationTypes/{Complex,Position,Quaternion,SpatialPose}.swift` all
declare `@unchecked Sendable`, yet their storage is SIMD vectors + `Bool` —
plainly `Sendable` when `T: Sendable` (which the generic bound already
requires). `@unchecked` disables the compiler's verification for zero
benefit and hides future regressions (concurrency spec red flag).
**Fix:** replace with plain `Sendable` conformance; if the compiler then
reports a genuine hole, that report is the finding. Applied: all four types
now use `extension <Type>: Sendable where T.SIMD{2,4}Storage: Sendable {}` —
`T: Sendable` on the generic bound doesn't extend to `SIMDScalar`'s
associated storage type, so the compiler needs that spelled out explicitly
to verify Sendable; `@unchecked` is gone. This is a genuine (expected)
compiler finding, not a rejection: the conditional bound had to propagate to
`WaveformPosition`/`WaveformQuaternion`/`WaveformSpatialPose` too, since each
wraps an array of the now-conditionally-Sendable type — without the matching
`where T.SIMD4Storage: Sendable` clause those three failed to build
(`stored property 'values' ... contains non-Sendable type 'T.SIMD4Storage'`).
Fixed in the same chunk; see chunk 05's Resolution section.

### F8. `depermaid` is a declared dependency no target uses — MINOR — RESOLVED (chunk 06, documented deviation)
`Package.swift` dependencies list it; no target references it. Every
`swift package resolve` fetches it for nothing (decision framework: fewer
dependencies).
**Fix:** remove from `Package.swift` (re-add ad hoc when generating
dependency diagrams). Applied: investigated instead of removing outright —
"no target references it" is true but doesn't mean the dependency is unused.
`depermaid` is invoked by `make mermaid` as a SwiftPM *command plugin*
(`swift package plugin depermaid …`), and command plugins are vended by a
package dependency directly, not by a target linking against it. Verified
empirically: removing `depermaid` from `Package.swift` and running
`swift package plugin --list` / `make mermaid` breaks plugin discovery
(`error: Unknown subcommand or plugin name 'depermaid'`, exit 64); re-adding
it restores both. Kept `depermaid` in `Package.swift` and added a note to the
`mermaid` target's `##` help text in `makefile` explaining why it must stay
resolved.

### F9. `FoundationCommon` is an empty product — MINOR — RESOLVED (chunk 02 + chunk 06)
The target contains only `Placeholder.swift` (0 bytes) yet ships as a
public library product with its own test target.
**Fix:** delete the target+product+tests, or move real shared code in;
an empty public product is API surface you must support. Applied: `Locked.swift`
now gives the target real content (chunk 02); `Placeholder.swift` deleted
along with the placeholder-only `FoundationCommonTests.swift` (an empty-body
XCTest stub) in chunk 06. `LockedTests.swift` (swift-testing, chunk 02) is
the target's real test content. `FoundationCommon` builds standalone with
only `Locked.swift`.

### F10. OpenCombine dependency — evaluate — MINOR
`FoundationTransactions` pulls OpenCombine + OpenCombineDispatch. If the
usage is event streams, `AsyncStream`/`AsyncSequence` covers it with zero
dependencies and native cancellation (concurrency spec preference; fewer
deps tie-breaker). **Fix:** inventory the Combine surface actually used;
if it's publishers-as-event-bus, plan a migration; if it's load-bearing
operators, keep and document why.
(inventoried in chunk 07 — see `../review-for-fixes/opencombine-inventory.md`;
recommendation: hybrid — migrate internals to `AsyncStream` (zero
operator-chain usage found), deprecate the 5 public OpenCombine-typed
properties for one release, then remove them + the dependency in a later
breaking-change chunk. Not marked RESOLVED — this was an evaluate finding,
not a fix.)

## Optimize

### O1. Mixed XCTest and swift-testing — MINOR
Tests: 10 files `import Testing`, 4 files XCTest. One process, two
frameworks (Chamber Match: reduce implementation variance).
**Fix:** converge new/ported tests on swift-testing; migrate the 4 XCTest
files opportunistically.

### O2. `@frozen` missing on hot numeric structs — MINOR (measure first)
`Complex`/`Position`/`Quaternion`/`SpatialPose` are `@inlinable`-heavy
(220 annotations) but not `@frozen` (performance spec suggests it for
numeric hot-path types when ABI stability allows). Library evolution mode
is off for SPM by default, so impact is limited — apply only with a
benchmark showing wins.

### O3. `components: [T]` allocates per access — MINOR (addressed in chunk 05)
Each read of `Complex.components` / `Position.components` allocates an
array. Fine for serialization; document it as not-for-hot-loops, or return
a tuple where call sites allow.

### O4. Cached `_isNormalized` invalidation is untested — MINOR (addressed in chunk 05)
The didSet-clears-flag pattern spans every setter of all four geometry
types; no test pins "mutate component → `isNormalized` false". One
parameterized test closes the class of regression.

## Suggested order

F2 (race) → F1 (silent failure) → F7 (compiler-verified Sendable) →
F5/F6 (after the Linux decision) → F3 → F8/F9 → O1–O4 opportunistically.
