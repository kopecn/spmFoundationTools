---
chunk: 07-opencombine-inventory
status: complete
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F10
last_updated: 2026-07-13
semver: 0.1.0
author: Nicholas Bergantz
---

# 07 — OpenCombine usage inventory (report-only)

**Deliverable:** a decision document — NO source changes. This chunk
gathers the evidence the migrate-vs-keep decision needs.

## Files

- Create: `.claude/review-for-fixes/opencombine-inventory.md`

## Design constraints

Inventory every OpenCombine symbol used across
`spm/Sources/FoundationTransactions/` (grep `Publisher|Subject|sink|
AnyCancellable|eraseToAnyPublisher|OpenCombine`), and for each usage
classify:

- **Event-stream** (publisher as a notification bus) → trivially replaced
  by `AsyncStream`.
- **Operator-chain** (map/filter/debounce/combineLatest…) → migration cost
  is real; name the operators.
- **Public API surface** (publishers exposed to consumers) → breaking
  change; list the consumers if visible.

End the report with a recommendation (migrate / keep / hybrid) and a rough
chunk count for a migration, so a follow-up scope-plan can pick it up.

## Acceptance criteria

- [ ] Report lists every file:line using an OpenCombine symbol
- [ ] Each usage classified into the three buckets
- [ ] `git diff --stat` shows ONLY the new report file
- [ ] `make build test` still passes (nothing changed)

## Out of scope

Any code change whatsoever.

## Resolution

Full inventory published at
[`../review-for-fixes/opencombine-inventory.md`](../review-for-fixes/opencombine-inventory.md).
Only 3 of 7 `FoundationTransactions` files touch OpenCombine (`Transaction.swift`,
`TransactionHandler.swift`, a doc-comment-only mention in `TransactionEvent.swift`).
24 live symbol usages found: 13 event-stream (bare `.send`/init on
`CurrentValueSubject`/`PassthroughSubject`, zero operators chained), 0
operator-chain, and 5 public API surface properties (`Transaction.statePublisher`/
`resultPublisher`/`eventPublisher`, `TransactionHandler.resourceStatePublisher`/
`unsolicitedEventPublisher`) with no in-repo consumers found — blast radius is
external/unknown. `OpenCombineDispatch` is imported but entirely unused (dead
sub-dependency). A private `cancellables: Set<AnyCancellable>` in
`TransactionHandler` is also dead (never populated).

**Recommendation: hybrid** — migrate all internal plumbing to `AsyncStream`
(zero operator-chain usage means no real migration cost), then deprecate the
public OpenCombine-typed properties for one release before removing them (and
the `OpenCombine`/`OpenCombineDispatch` dependency) in a later breaking-change
chunk. Rough estimate: 3 chunks now + 1 deferred breaking-change chunk.
