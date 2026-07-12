---
plan: swift-audit-fixes
status: pending
last_updated: 2026-07-11
semver: 0.0.1
author: Nicholas Bergantz
---

# Action Plan — Swift Audit Fixes (spmFoundationTools)

**Goal:** close every finding in
[`../review-for-fixes/2026-07-11-swift-audit.md`](../review-for-fixes/2026-07-11-swift-audit.md)
— that audit is the authoritative statement of each defect; chunks
back-reference its finding IDs (F1–F10, O1–O4). **Decision on record:
Linux is a required build target** — portability findings are fixed, not
documented away.

## Conventions every chunk inherits

1. **Gate:** `make build test` green at the end of every chunk (plus
   `make format` before finishing).
2. **TDD:** failing test first where the finding is behavioral; regression
   tests are named `test<FindingID>_...` so the audit maps to the suite.
3. **New tests use swift-testing** (`import Testing`), not XCTest (audit O1
   policy: converge; migrate old XCTest files only when a chunk already
   owns that file).
4. **Stay in scope:** touch only the chunk's file list; adjacent issues go
   in completion notes.
5. **Frontmatter:** tracking triad + `status: pending` → update as you work.
6. If a fix changes behavior the audit didn't anticipate, update the audit
   file's finding (bump its `semver`) in the same chunk.

## Deferred (recorded, not chunked)

- **O2** `@frozen` on numeric structs — measure-first; no benchmark exists.
- **O3** `components: [T]` allocation — docstring note only, folded into 05.
- **F4** `NSRecursiveLock` restructure — investigate note added in 04;
  full restructure only alongside the F10 decision.

## Dependency graph

```
01 sincos-portability ─────────┐
02 locked-and-namedpipe ───────┼──► 08 linux-verification
03 persistence-errors          │
04 transaction-timeout         │
05 geometry-types-hardening ───┘
06 package-hygiene   (after 02 — Placeholder deletion needs Locked landed)
07 opencombine-inventory   (independent, report-only)
```

01–05 are mutually independent; run in any order or parallel.

## Chunk index

| # | Chunk | Findings | Depends on |
|---|---|---|---|
| 01 | [sincos-portability](01-sincos-portability.md) | F5 | — |
| 02 | [locked-and-namedpipe](02-locked-and-namedpipe.md) | F2, F6, F9(populate) | — |
| 03 | [persistence-errors](03-persistence-errors.md) | F1 | — |
| 04 | [transaction-timeout](04-transaction-timeout.md) | F3, F4(note) | — |
| 05 | [geometry-types-hardening](05-geometry-types-hardening.md) | F7, O4, O3(doc) | — |
| 06 | [package-hygiene](06-package-hygiene.md) | F8, F9(cleanup) | 02 |
| 07 | [opencombine-inventory](07-opencombine-inventory.md) | F10 | — |
| 08 | [linux-verification](08-linux-verification.md) | F5/F6 proof | 01, 02 |
