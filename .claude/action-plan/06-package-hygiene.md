---
chunk: 06-package-hygiene
status: complete
depends_on: [02]
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F8, §F9
last_updated: 2026-07-13
semver: 0.1.0
author: Nicholas Bergantz
---

# 06 — Package hygiene

**Deliverable:** no unused dependencies, no placeholder files.

## Files

- Edit: `Package.swift`
- Delete: `spm/Sources/FoundationCommon/Placeholder.swift` (empty; the
  target now holds `Locked.swift` from chunk 02)
- Edit if needed: `spm/Tests/FoundationCommonTests/*` (remove any
  placeholder-only test)

## Design constraints

1. Remove `depermaid` from `Package.swift` dependencies (no target uses
   it). The Makefile `mermaid` target may invoke it as a CLI — check first:
   if `make mermaid` runs `swift package … depermaid`-style plugins,
   re-adding it ad hoc is the documented workflow; note whichever is true
   in the Makefile target's `##` help text.
2. Delete `Placeholder.swift`; `FoundationCommon` must still build with
   real content (chunk 02's `Locked.swift`).
3. Run `swift package resolve` and commit-ready `Package.resolved` changes.

## TDD steps

1. `make build test` before, edits, `make build test` after — plus
   `make mermaid` still functions (or its help text explains the manual
   step).

## Acceptance criteria

- [ ] `grep -n "depermaid" Package.swift` → no hits
- [ ] `find spm/Sources -name "Placeholder.swift"` → no hits
- [ ] `make build test` passes; `make mermaid` behavior verified and noted

## Out of scope

OpenCombine (chunk 07); version bumps; adding new products.

## Resolution

**F8 — `depermaid` is required, not removed (documented deviation).**
Empirically verified: `depermaid` in `Package.swift`'s `dependencies:` is what
makes it discoverable as a SwiftPM command plugin. Tested by temporarily
removing the dependency and running `swift package plugin --list` (empty
output, plugin no longer found) and `make mermaid` (`error: Unknown
subcommand or plugin name 'depermaid'`, exit 64). Re-added the dependency
(`git checkout -- Package.swift`) and both worked again. SwiftPM command
plugins are vended by a package dependency itself — no target needs to
depend on it, which is why the audit's static "no target references it"
observation was true but did not imply the dependency was unused. `depermaid`
stays in `Package.swift`. Added a note to the `mermaid` target's `##` help
text in `makefile` explaining the dependency is intentional (alongside the
pre-existing, unrelated `open-github` diff already present in that file from
the user's in-progress work).

**F9 — cleanup complete.** Deleted `spm/Sources/FoundationCommon/Placeholder.swift`
(1-byte empty file). Also deleted `spm/Tests/FoundationCommonTests/FoundationCommonTests.swift`,
which contained only a placeholder XCTest (`testBasic` with an empty body) —
`LockedTests.swift` (chunk 02, swift-testing) is the target's real test
content and was left untouched. `FoundationCommon` builds standalone
(`swift build --target FoundationCommon`) with only `Locked.swift` as
content.

**Package.resolved:** unchanged — `swift package resolve` produced no diff,
since no dependency changed.

**Gate:** `make build test` passes, 415 tests in 67 suites, 0 failures.
`make mermaid` verified functioning (regenerates the dependency diagram via
the `depermaid` plugin, unchanged behavior).

**Scope note:** `make format` reformatted several files outside this chunk's
scope (under `FoundationTypes/Extensions/`, `FoundationInterfaces/Pipes/`,
`PrecisionTime/`, etc.) — these were clean at HEAD (a concurrent chunk 05
commit had landed mid-session) but not yet reformatted to the current
`.swift-format.json` config. Restored all of them via
`git show HEAD:<path> > <path>` per the chunk convention; only
`Package.swift` (net no-op after test-and-revert), `makefile`,
`Placeholder.swift` (deleted), and `FoundationCommonTests.swift` (deleted)
remain in this chunk's diff.
