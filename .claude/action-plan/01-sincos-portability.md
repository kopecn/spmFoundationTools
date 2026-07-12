---
chunk: 01-sincos-portability
status: complete
depends_on: []
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F5
last_updated: 2026-07-11
semver: 0.1.0
author: Nicholas Bergantz
---

# 01 — Portable sincos helper

**Deliverable:** one internal helper replaces all Darwin-only
`__sincos`/`__sincosf` call sites in `FoundationTypes` (20 sites — see
Resolution notes for the corrected count).

## Files

- Create: `spm/Sources/FoundationTypes/Support/SinCos.swift`
- Edit: `spm/Sources/FoundationTypes/Complex.swift` (:123, :150),
  `Position.swift` (10 sites, :120–:217, including `sphericalISO`),
  `Quaternion.swift` (8 sites, :150–:228)
- Create: `spm/Tests/FoundationTypesTests/SinCosTests.swift`

## Recipe

```swift
// SinCos.swift
#if canImport(Darwin)
import Darwin
#endif

@usableFromInline
internal func sincos(_ x: Double) -> (sin: Double, cos: Double) {
    #if canImport(Darwin)
    var s = 0.0; var c = 0.0
    __sincos(x, &s, &c)
    return (s, c)
    #else
    return (Foundation.sin(x), Foundation.cos(x))   // compilers fuse the pair
    #endif
}
// + Float overload using __sincosf / sinf, cosf
```

Every call site becomes `let (s, c) = sincos(angle)` — no other logic
changes. Keep `@usableFromInline` so the `@inlinable` constructors that call
it still compile.

## TDD steps

1. Failing test: `sincos(x)` equals `(sin(x), cos(x))` over a grid including
   0, ±π/2, ±π, 1e-9, 1e9 (exact equality on Darwin where `__sincos` is the
   same libm; atol 1e-15 otherwise). Plus one existing-behavior pin: a
   `Quaternion(axis:angle:)` value before/after the refactor is bitwise
   identical (compute expected with the old code path first).
2. Add helper, reroute the 14 sites. 3. `make build test` green.

## Acceptance criteria

- [x] `grep -rn "__sincos" spm/Sources/` → hits only inside `SinCos.swift`
- [x] Full `FoundationTypesTests` suite passes unchanged
- [x] `make build test` passes

## Out of scope

Any other Darwin API (chunk 02 owns the lock); math behavior changes;
Float/Double generic unification.

## Resolution notes

- **Site count correction:** the actual call-site count was **20**, not the
  14 stated in this chunk and in audit F5 (Complex.swift 2, `Position.swift`
  **10** — the `sphericalISO` initializers at :186-217 were omitted from the
  original count/line-range — `Quaternion.swift` 8). All 20 sites were
  rerouted; the audit's F5 finding and this chunk's file header were
  corrected accordingly (see audit semver bump below). No behavior change,
  no new files beyond what was already planned.
- **TDD sequencing:** `SinCos.swift` and `SinCosTests.swift` were authored
  together (rather than a strict red-green-red), but the test suite was run
  and confirmed green *before* touching any call site, against the
  still-unmodified `Quaternion.swift` — so the existing-behavior pin
  (`testF5_quaternionAxisAngleDoubleUnchanged` /
  `...FloatUnchanged`) captured true pre-refactor bit patterns from a
  standalone Darwin probe (`__sincos` vs. axis-angle formula) before the
  refactor, then verified unchanged after.
- **Float grid tolerance:** at `x = ±1e9`, `Float`'s `__sincosf` and the
  separate `sinf`/`cosf` fallback differ by ~1 ULP due to FP32 range
  reduction — not bit-identical even on Darwin. The `Float` grid test uses
  a `1e-6` tolerance instead of exact equality; the `Double` grid remains
  exact-equality on Darwin as specified (verified exact across the full
  grid including ±1e9).
- **Scope guard:** `make format` (run per convention 1) reformats the whole
  `spm/Sources` and `spm/Tests` trees, which touched ~24 files outside this
  chunk's list (pre-existing formatting drift unrelated to this fix). Those
  files were restored to their committed state; only `Complex.swift`,
  `Position.swift`, `Quaternion.swift`, and the two new files were
  formatted, keeping the diff to the chunk's file list.
