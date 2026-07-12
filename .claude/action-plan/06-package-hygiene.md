---
chunk: 06-package-hygiene
status: pending
depends_on: [02]
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F8, §F9
last_updated: 2026-07-11
semver: 0.0.1
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
