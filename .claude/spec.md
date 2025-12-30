# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FoundationTools is a Swift Package Manager (SPM) project providing high-performance, SIMD-optimized mathematical types and utilities for 3D spatial computing, signal processing, and precision timing. The project emphasizes LLVM-friendly code patterns for optimal vectorization on Linux/x86_64 targets.

Philosophy: KISS (Keep It Simple, Stupid)

## Common Commands

### Building and Testing
```bash
# Build the project (release mode)
swift build -c release

# Run all tests (excludes netcat tests by default)
swift test --no-parallel

# Run specific test targets
swift test --filter FoundationTypesTests
swift test --filter FoundationToolsTests
swift test --filter FoundationCommonTests

# Run netcat integration tests (special cases)
RUN_NETCAT_CLIENT_TESTS=1 swift test --filter "connectClientToNetCat" --no-parallel
RUN_NETCAT_SERVER_TESTS=1 swift test --filter "connectServerToNetCat" --no-parallel
```

### Code Formatting
```bash
# Format all source code (uses .swift-format.json config)
make format

# Or manually:
swift-format --configuration .swift-format.json format --in-place --recursive spm/Sources
swift-format --configuration .swift-format.json format --in-place --recursive spm/Tests
```

### Package Management
```bash
# Update dependencies
make update-packages
# OR
swift package update

# Clean build artifacts
make clean
# OR
swift package clean && rm -rf .build
```

### Versioning
```bash
# Show current version
make version

# Bump version (creates and pushes git tag)
make bump-patch  # 1.2.3 → 1.2.4
make bump-minor  # 1.2.3 → 1.3.0
make bump-major  # 1.2.3 → 2.0.0
```

### Maintenance
```bash
# Generate dependency diagram (Mermaid format)
make mermaid

# Full release process
make release  # Runs clean, build, test
```

## Project Structure

### Module Architecture

The project consists of three main modules with clear dependency hierarchy:

```
FoundationCommon (base utilities)
    ↑
    ├── FoundationTypes (SIMD math types)
    │   └── depends on: kvSIMD
    └── FoundationTools (higher-level utilities)
        ├── depends on: FoundationCommon, FoundationTypes
        └── depends on: Logging (swift-log)
```

All source code is located in `spm/Sources/`, tests in `spm/Tests/`.

### FoundationTypes Module

Core SIMD-optimized mathematical types using `SIMD2<T>`, `SIMD3<T>`, and `SIMD4<T>` for storage:

**Basic Types:**
- `Complex<T>` - Complex numbers (2D) with phasor/polar form support
- `Position<T>` - 3D spatial coordinates with cylindrical/spherical conversions
- `Quaternion<T>` - 3D rotations with axis-angle and Euler angle support
- `SpatialPose<T>` - Combined position and orientation

**Waveform Types (Time-Series Data):**
- `Waveform1D<T, U>` - Uniformly sampled 1D signals with temporal metadata
- `WaveformPosition<T>` - Time-varying 3D positions
- `WaveformQuaternion<T>` - Time-varying orientations
- `WaveformSpatialPose<T>` - Time-varying poses

**Precision Time Types:**
- `PrecisionTimestamp` - High-precision timestamps with attosecond (10^-18s) resolution
- `PrecisionTimeInterval` - High-precision time intervals
- `Timescale` - Time scale specifications (TAI, UTC, TT, TCB)
- `ReferenceFrame` - Spatial reference frames

**Type Parameters:**
- `T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable` (typically `Float` or `Double`)
- Convenient typealiases provided: `ComplexDouble`, `FloatPosition`, `DoubleQuaternion`, etc.

**Organization Pattern:**
- Core type definitions in root of `FoundationTypes/`
- Extensions organized by type in `Extensions/TypeName/TypeName+Feature.swift`
- Extension categories: `BaseExtensions`, `Codable`, `Normalization`, `Arithmetic`, `RotationMatrixElements`

### FoundationTools Module

Higher-level utilities:
- `PersistenceStorage` - Type-safe, thread-safe persistent storage actor
  - Uses `UserDefaults` on macOS, JSON file on Linux
  - Type-safe keys via `PersistenceKey<T>`

### FoundationCommon Module

Base utilities and common functionality (minimal - currently just placeholder).

## Critical Development Patterns

### SIMD Optimization Philosophy

This codebase is optimized for LLVM IR vectorization on Linux/x86_64. When working with FoundationTypes:

1. **Use SIMD Storage Directly**
   - All math types use `SIMD2<T>`, `SIMD3<T>`, or `SIMD4<T>` for internal storage
   - Public accessors (`.x`, `.y`, `.real`, etc.) are `@inlinable` computed properties
   - Storage fields must be `@usableFromInline` when accessed in `@inlinable` functions

2. **Inlining is Critical**
   - Mark ALL hot-path functions, initializers, and computed properties as `@inlinable`
   - This includes: arithmetic operators, magnitude calculations, normalizations, type conversions
   - Functions <10 lines should almost always be `@inlinable`

3. **Prefer SIMD Intrinsics**
   - Use `simd_length()` instead of manual sqrt of dot product
   - Use `simd_length_squared()` instead of manual dot product
   - Use `simd_normalize()` instead of manual normalization
   - Use `__sincos()` / `__sincosf()` for simultaneous sin/cos calculations
   - Use SIMD vector operations instead of component-wise scalar operations

4. **Minimize Branching**
   - Avoid complex control flow in mathematical operations
   - Prefer conditional moves (`condition ? a : b`) over if/else in hot paths

5. **Normalization Caching**
   - Types maintain an internal `_isNormalized: Bool` flag for optimization
   - Flag is set to `false` when any component is modified
   - Flag is set to `true` after normalization or when constructed via normalizing initializers
   - Use `isNormalized` property to check cached flag (fast)
   - Use `isUnit` property for runtime verification (computes magnitude, slower)

### Code Review for SIMD/LLVM Optimization

A `/codeReviewLLVM` skill is available that performs comprehensive LLVM IR optimization review. See `.claude/commands/codeReviewLLVM.md` for the complete checklist and review format.

### Float vs Double Specializations

Many initializers that use trigonometric functions have separate implementations for `Float` and `Double`:
- `Double` versions use `__sincos()`
- `Float` versions use `__sincosf()`
- Both are marked `@inlinable` for cross-module optimization

### Sendable Conformance

All types in FoundationTypes use `@unchecked Sendable` for concurrency safety since they're value types with `Sendable` components.

### Coordinate System Conventions

**Spherical Coordinates:**
- Default: Mathematical/geographic convention (elevation from equator, -π/2 to +π/2)
- Alternative: ISO 80000-2:2019 physics convention (polar/colatitude from north pole, 0 to π)
  - Use `sphericalISO` initializers for ISO convention

**Quaternions:**
- Storage: `(x, y, z, w)` where xyz is imaginary/vector part, w is real/scalar
- Normalization: Unit quaternions represent rotations

## Code Style and Formatting

Configuration in `.swift-format.json`:
- 4-space indentation
- 120 character line length
- Break before each function argument
- File-scoped declarations should be `private` (not `fileprivate`)
- No block comments (use `//` instead of `/* */`)
- No semicolons
- Triple-slash doc comments (`///`)

Run `make format` before committing changes.

## Testing Guidelines

- Tests are organized by module: `FoundationTypesTests/`, `FoundationToolsTests/`, `FoundationCommonTests/`
- Test files named `TypeNameTests.swift`
- Use `swift test --no-parallel` to avoid concurrency issues
- Netcat integration tests require environment variables to run (excluded by default)

## Platform Requirements

- Swift 6.1+
- Platforms: macOS 14+, iOS 16+, tvOS 16+, watchOS 9+
- Primary optimization target: Linux/x86_64 with AVX/AVX2

## Dependencies

- `swift-log` - Logging infrastructure
- `kvSIMD.swift` - Additional SIMD utilities
- `depermaid` - Dependency diagram generation (dev tool)

## File Naming Conventions

- Core types: `TypeName.swift` in module root
- Extensions: `Extensions/TypeName/TypeName+Feature.swift`
- Tests: `Tests/ModuleNameTests/TypeNameTests.swift`
- Protocols: `Protocols/ProtocolName.swift`
