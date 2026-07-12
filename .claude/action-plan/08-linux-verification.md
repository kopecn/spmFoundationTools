---
chunk: 08-linux-verification
status: pending
depends_on: [01, 02]
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F5, §F6 (proof); decision: Linux is a required target
last_updated: 2026-07-11
semver: 0.0.1
author: Nicholas Bergantz
---

# 08 — Linux build verification

**Deliverable:** a repeatable `make linux-test` target proving the package
builds and tests on Linux, plus fixes for whatever it flushes out.

## Files

- Edit: `makefile` (add `linux-build` / `linux-test` targets)
- Edit: whatever the Linux build breaks (expected: small `#if canImport`
  patches; anything larger → stop and report)

## Recipe

```make
linux-test:  ## Build & test in a Linux container (requires Docker)
	docker run --rm -v "$(PWD)":/pkg -w /pkg swift:6.1 \
		swift test --package-path .
```

Known Linux hazards to check when it runs: `Foundation` file APIs in
`PersistenceStorage`/`NamedPipeChannel` (mkfifo/FileHandle semantics),
`OpenCombine` (designed for Linux — should pass), kvSIMD (its purpose —
should pass). `__sincos`/`OSAllocatedUnfairLock` are already gone (chunks
01, 02).

## TDD steps

1. Add the target; run it; triage failures smallest-first. Platform
   differences get `#if os(Linux)` only when behavior genuinely differs —
   never copy-paste forks of shared logic.
2. If a failure implies a design problem (not a conditional-compile
   patch), STOP: record it as a new finding in the audit file and leave
   this chunk `in_progress`.

## Acceptance criteria

- [ ] `make linux-test` exits 0 on this machine
- [ ] No test is skipped-on-Linux without a comment justifying it
- [ ] `make build test` (macOS) still passes

## Out of scope

CI pipeline wiring (no CI exists in this repo yet — note it as a follow-up);
performance on Linux.
