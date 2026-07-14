---
chunk: 04-transaction-timeout
status: complete
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F3, §F4
last_updated: 2026-07-13
semver: 0.1.0
author: Nicholas Bergantz
---

# 04 — Structured transaction timeout

**Deliverable:** the timeout in `TransactionHandler` becomes a cancellable
child task instead of a fire-and-forget Dispatch work item.

## Files

- Edit: `spm/Sources/FoundationTransactions/TransactionHandler.swift`
- Edit/Create: `spm/Tests/FoundationToolsTests/` transaction timeout tests
  (place beside the existing transaction tests; create the file if none)

## Recipe

Replace `DispatchQueue.global().asyncAfter(deadline: .now() + timeout,
execute: workItem)` (`:513`) with:

```swift
let timeoutTask = Task { [weak self] in
    do {
        try await Task.sleep(for: .seconds(timeout))
        self?.handleTimeout(for: transactionID)     // existing work-item body
    } catch { /* CancellationError — transaction completed first */ }
}
// store timeoutTask alongside the transaction; cancel it on completion:
timeoutTask.cancel()
```

Read the surrounding lifecycle first: wherever the old `DispatchWorkItem`
was cancelled/retained, the `Task` handle takes its place. The stored task
must be cancelled on every completion path (success, failure, external
cancel).

`NSRecursiveLock` (F4, `:140`) is NOT restructured here — add a
`// AUDIT F4:` comment at the declaration noting the restructure is
deferred, and list the re-entrant call paths you observe in the completion
notes.

## TDD steps

1. Failing tests (swift-testing): (a) a transaction that completes before
   the timeout never fires the timeout handler (assert via injected hook,
   waiting > timeout); (b) a transaction that does not complete fires it
   once at ~timeout; (c) cancelling the transaction cancels the pending
   timeout (no late fire).
2. Implement. 3. `make build test` green.

## Acceptance criteria

- [ ] `grep -n "asyncAfter" spm/Sources/FoundationTransactions/` → no hits
- [ ] All three timeout-lifecycle tests pass
- [ ] `// AUDIT F4:` comment present at the NSRecursiveLock declaration
- [ ] `make build test` passes

## Out of scope

OpenCombine migration (chunk 07); NSRecursiveLock restructure; other
Transaction files unless the task handle storage requires touching them.

## Resolution

Replaced `timeoutTimers: [Int: AnyCancellable]` (wrapping a `DispatchWorkItem`
cancel) with `timeoutTasks: [Int: Task<Void, Never>]`. `startTimeout(for:)` now
spawns `Task { [weak self] in try await Task.sleep(for: .seconds(timeout));
self?.handleTimeout(transactionID:) } catch { /* cancelled */ }` and stores the
handle; `cancelTimeout(for:)` calls `.cancel()` on the stored task instead of
the `AnyCancellable`. `handleTimeout` itself is unchanged — it already guarded
on `!transaction.isTerminal`, so no behavior change there. Every existing
completion path (`processResponse`, `processError`, `cancel`,
`cancelAllActiveTransactions`) already routed through `cancelTimeout(for:)`,
so no call sites needed to change beyond the storage type.

Added the `// AUDIT F4:` comment directly above the `NSRecursiveLock`
declaration (`TransactionHandler.swift:140`, now with the comment above it).

### Deviations from the literal recipe

- **No transaction tests existed anywhere, and no `FoundationTransactions`
  test target existed in `Package.swift`.** The chunk's file list said "place
  beside the existing transaction tests" — there were none. Added a
  `FoundationTransactionsTests` test target to `Package.swift` (mirrors the
  existing per-module pattern: `FoundationCommonTests`, `FoundationTypesTests`)
  and created `spm/Tests/FoundationTransactionsTests/TransactionHandlerTests.swift`.
- **No injected hook was added to the source.** The recipe suggested asserting
  scenario (a) "via injected hook." Instead, all three tests assert on the
  existing public `Transaction.state` (`.completed` / `.timedOut` /
  `.cancelled`) after waiting past the deadline. This is behavior-level
  (matches decision-framework's "tests validate behavior, not implementation
  detail") and avoids adding a test-only `@Sendable` callback property to a
  type that is already `@unchecked Sendable`. Single-fire is structurally
  guaranteed by the code shape (one `Task.sleep` + one call), so no counting
  hook was needed to prove "fires once."
- Test command/category used `.parallel` to avoid interacting with the
  serial/exclusive queue-advancement side effects, keeping the three tests
  isolated to timeout lifecycle only.

### F4 re-entrant call-path observations

The one concrete re-entrant path justifying `NSRecursiveLock` today:
`processResponse`, `processError`, `cancel`, and `handleTimeout` each take
`lock` and then call `cleanupTransaction(_:)`. For a serial transaction whose
completion drains the serial queue, `cleanupTransaction` calls the **public**
`updateResourceState(.idle)`, which itself calls `lock.lock()` — a nested
acquisition on the same thread. A plain `NSLock`/`Mutex` would deadlock here.
No other public entry point was found to re-enter the lock on the same call
stack; this is the sole path, and restructuring it (e.g., splitting
`updateResourceState` into a locked/unlocked pair, or moving to an actor) is
deferred per the plan's dependency note (alongside the F10 OpenCombine
decision), not attempted in this chunk.
