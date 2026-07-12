---
chunk: 07-opencombine-inventory
status: pending
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F10
last_updated: 2026-07-11
semver: 0.0.1
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
