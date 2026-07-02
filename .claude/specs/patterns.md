# Development Patterns

## SIMD Optimization Philosophy

This codebase is optimized for LLVM IR vectorization on Linux/x86_64.

### 1. Use SIMD Storage Directly
- All math types store via `SIMD2<T>`, `SIMD3<T>`, or `SIMD4<T>`
- Public accessors (`.x`, `.y`, `.real`, etc.) are `@inlinable` computed properties
- Storage fields must be `@usableFromInline` when accessed in `@inlinable` functions

### 2. Inlining is Critical
- Mark ALL hot-path functions, initializers, and computed properties `@inlinable`
- Includes: arithmetic operators, magnitude, normalization, type conversions
- Functions under ~10 lines should almost always be `@inlinable`

### 3. Prefer SIMD Intrinsics
- `simd_length()` — not manual `sqrt(dot(v, v))`
- `simd_length_squared()` — not manual dot product
- `simd_normalize()` — not manual division
- `__sincos()` / `__sincosf()` — for simultaneous sin/cos
- SIMD vector ops — not component-wise scalar loops

### 4. Minimize Branching
- Avoid complex control flow in math operations
- Prefer ternary (`condition ? a : b`) over `if/else` in hot paths

### 5. Normalization Caching
- Types maintain `_isNormalized: Bool` — set `false` on any mutation, `true` after normalize or via normalizing initializer
- `isNormalized` — reads cached flag (fast)
- `isUnit` — recomputes magnitude (slower, runtime check)

---

## Float vs Double Specializations

Trig initializers have separate `Float` and `Double` implementations:
- `Double` versions use `__sincos()`
- `Float` versions use `__sincosf()`
- Both marked `@inlinable` for cross-module optimization

---

## Sendable Conformance

All FoundationTypes use `@unchecked Sendable` — they are value types with `Sendable` components.

---

## Coordinate System Conventions

**Spherical Coordinates:**
- Default: mathematical/geographic (elevation from equator, −π/2 to +π/2)
- ISO 80000-2:2019: polar/colatitude from north pole (0 to π) — use `sphericalISO` initializers

**Quaternions:**
- Storage: `(x, y, z, w)` — xyz is imaginary/vector part, w is real/scalar
- Unit quaternions represent rotations

---

## Code Review

`/codeReviewLLVM` skill performs comprehensive LLVM IR optimization review.
See `.claude/commands/codeReviewLLVM.md` for the full checklist and output format.
