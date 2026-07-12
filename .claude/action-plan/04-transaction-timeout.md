---
chunk: 04-transaction-timeout
status: pending
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F3, §F4
last_updated: 2026-07-11
semver: 0.0.1
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
