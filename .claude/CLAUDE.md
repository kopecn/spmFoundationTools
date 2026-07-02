# CLAUDE.md

FoundationTools is an SPM project providing SIMD-optimized mathematical types and utilities for 3D spatial computing, signal processing, and precision timing. Philosophy: KISS.

## Common Commands

```bash
swift build -c release                          # build
swift test --no-parallel                        # run all tests
swift test --filter FoundationTypesTests        # run one target
make format                                     # format (uses .swift-format.json)
make update-packages                            # update dependencies
make clean                                      # clean build artifacts
make mermaid                                    # regenerate dependency diagram
make bump-patch / bump-minor / bump-major       # version tagging
make release                                    # clean → build → test
```

## Module Architecture

Five modules. Source in `spm/Sources/`, tests in `spm/Tests/`.

```
FoundationCommon    (no dependencies — base utilities)
FoundationInterfaces (no dependencies — shared protocols)
    ↑
    ├── FoundationTypes (+ kvSIMD)
    ├── FoundationTools (+ FoundationCommon, FoundationTypes, FoundationInterfaces, Logging)
    └── FoundationTransactions (+ FoundationInterfaces, OpenCombine)
```

## Platform & Dependencies

- Swift 6.1+ · macOS 14+ · iOS 16+ · tvOS 16+ · watchOS 9+
- Primary optimization target: Linux/x86_64 (AVX/AVX2)
- Dependencies: `swift-log`, `kvSIMD.swift`, `OpenCombine`, `depermaid` (dev)

## Subspecs

Fetch these only when the task requires deeper context:

| File | When to read |
|---|---|
| `.claude/specs/modules.md` | Editing or extending any module — type APIs, file layout |
| `.claude/specs/patterns.md` | Writing performance-critical code — SIMD, inlining, coordinate conventions |
| `.claude/specs/style.md` | Formatting, testing, or file naming questions |
