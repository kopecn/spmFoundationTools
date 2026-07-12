---
chunk: 03-persistence-errors
status: pending
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F1
last_updated: 2026-07-11
semver: 0.0.1
author: Nicholas Bergantz
---

# 03 — Surface PersistenceStorage failures

**Deliverable:** no silent data loss in the persistence path.

## Files

- Edit: `spm/Sources/FoundationTools/PersistenceStorage.swift`
- Edit/Create: `spm/Tests/FoundationToolsTests/PersistenceStorageTests.swift`

## Design constraints

1. The save path (`:290–:305`) stops `print`-and-swallowing: the internal
   save becomes `throws`; the public trigger either propagates `throws` or,
   where fire-and-forget is required by the existing API shape, logs via
   `swift-log` (`Logger(label: "FoundationTools.PersistenceStorage")`) at
   `.error` WITH the underlying error — never `print` (error-handling
   spec: preserve the underlying error).
2. The `try? JSONEncoder().encode(AnyEncodable(value))` loop (`:294`)
   stops silently dropping unencodable values: collect skipped keys and
   log one `.warning` listing them; a fully-failed save throws.
3. Read the whole file first — mirror its existing API style; do not
   redesign the storage class.

## TDD steps

1. Failing tests: (a) saving a storage containing an unencodable value logs
   a warning naming the key and still persists the encodable keys
   (round-trip them back); (b) a save to an unwritable URL surfaces an
   error (thrown or logged at `.error`) — assert via a captured LogHandler.
2. Implement. 3. `make build test` green.

## Acceptance criteria

- [ ] `grep -n "print(" spm/Sources/FoundationTools/PersistenceStorage.swift` → no hits
- [ ] Skipped-key warning test passes; failed-save surfacing test passes
- [ ] `make build test` passes

## Out of scope

Changing the storage format; AnyEncodable redesign; NamedPipeChannel.
