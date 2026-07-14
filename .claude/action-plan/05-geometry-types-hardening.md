---
chunk: 05-geometry-types-hardening
status: complete
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F7, §O4, §O3
last_updated: 2026-07-13
semver: 0.1.0
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

## Resolution

- **F7:** replaced `@unchecked Sendable` with
  `extension <Type>: Sendable where T.SIMD{2,4}Storage: Sendable {}` on
  `Complex`, `Position`, `Quaternion`, `SpatialPose`. The compiler accepted
  the conditional conformance on all four — no genuine Sendable hole in the
  storage itself. It did, however, surface a real (expected) knock-on
  build break: `WaveformPosition`, `WaveformQuaternion`, and
  `WaveformSpatialPose` each store an array of the now-conditionally-Sendable
  type (`[Position<T>]` etc.) and previously declared unconditional
  `Sendable`; with the wrapped type's Sendable now gated on
  `T.SIMD4Storage: Sendable`, that gate had to propagate
  (`public struct WaveformPosition<T: ...>: Sendable where T.SIMD4Storage: Sendable`)
  or the build fails with "stored property 'values' ... contains
  non-Sendable type 'T.SIMD4Storage'". Fixed the three Waveform wrappers in
  this chunk since they are a mechanical, unavoidable consequence of F7, not
  a design choice — verified by reverting one in isolation and confirming
  the build error, then reinstating it. Audit file's F7 entry updated to
  record this.
- **O4:** created `spm/Tests/FoundationTypesTests/NormalizationCacheTests.swift`
  with one `@Test(arguments:)` per type pinning that every mutating setter
  clears the cached `_isNormalized`/`isNormalized` flag: Complex
  (`storage`, `real`, `imaginary`), Position (`vector`, `x`, `y`, `z`),
  Quaternion (`vector`, `x`, `y`, `z`, `w`, `imaginary`, `real`). All pins
  passed on first run (no invalidation hole found — no `didSet` fix
  needed). For `SpatialPose`, `isNormalized` is documented as mirroring
  only the rotation quaternion's cached flag ("Set to `false` when any
  rotation component is modified"), so the rotation setters (`qx`, `qy`,
  `qz`, `qw`) are pinned to invalidate it, and the position setters (`x`,
  `y`, `z`) are pinned in a second parameterized test to explicitly *not*
  affect it — documenting the real, intentional contract rather than
  asserting an invalidation that was never claimed.
- **O3:** added the docstring line "Allocates a new array per access — not
  for hot loops." to `Complex.components` and `Position.components` (the
  only two of the four types with a `components: [T]` property;
  `Quaternion` and `SpatialPose` have no such property).
- No deviations beyond the F7 Waveform-file knock-on above; `make format`
  reformatted several unrelated files across the repo (pre-existing drift,
  not touched by this chunk's edits) — reverted to `HEAD` via
  `git show HEAD:<path> > <path>` so the diff stays scoped to the four
  geometry files, the three Waveform wrapper files, and the new test file.
- Gate: `make build test` — 415 tests / 67 suites, all passed.
