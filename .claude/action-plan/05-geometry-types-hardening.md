---
chunk: 05-geometry-types-hardening
status: pending
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F7, §O4, §O3
last_updated: 2026-07-11
semver: 0.0.1
author: Nicholas Bergantz
---

# 05 — Geometry types: verified Sendable + cache-invalidation tests

**Deliverable:** the four geometry structs drop `@unchecked` and gain the
missing `_isNormalized`-invalidation regression tests.

## Files

- Edit: `spm/Sources/FoundationTypes/Complex.swift`, `Position.swift`,
  `Quaternion.swift`, `SpatialPose.swift` (the `@unchecked Sendable`
  declarations + `components` docstrings)
- Create: `spm/Tests/FoundationTypesTests/NormalizationCacheTests.swift`

## Design constraints

1. **F7:** replace `@unchecked Sendable` with plain `Sendable` on all four
   structs. The generic bound already requires `T: Sendable`; storage is
   SIMD + `Bool`, so the compiler should verify it. If the compiler
   rejects any of them, do NOT reinstate `@unchecked` silently — the error
   message is a finding: record it in the completion notes and fix the
   underlying non-Sendable member instead.
2. **O4:** for each type and each mutating setter (`storage`, `x/y/z/w`,
   `vector`, position/rotation setters on SpatialPose), pin: construct
   normalized (`isNormalized == true`), mutate one component,
   assert `isNormalized == false` while `isUnit` recomputes truthfully.
   Parameterize with swift-testing `@Test(arguments:)` rather than 30
   hand-written cases.
3. **O3:** add one docstring line to each `components` property: "Allocates
   a new array per access — not for hot loops." No code change.

## TDD steps

1. Write the invalidation tests first (they should pass against current
   behavior — they are regression pins; any that FAIL expose a real
   invalidation hole: fix the `didSet` and note it).
2. Swap the Sendable conformances. 3. `make build test` green.

## Acceptance criteria

- [ ] `grep -rn "@unchecked Sendable" spm/Sources/FoundationTypes/` → no hits
- [ ] Every mutating setter of the four types appears in the invalidation test arguments (grep the test for each property name)
- [ ] `make build test` passes

## Out of scope

`@frozen` (deferred O2); math behavior; the Normalizable protocol split.
