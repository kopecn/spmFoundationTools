---
chunk: 08-linux-verification
status: blocked
depends_on: [01, 02]
audit: ../review-for-fixes/2026-07-11-swift-audit.md §F5, §F6 (proof); decision: Linux is a required target
last_updated: 2026-07-15
semver: 0.1.0
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

## Blocker — ON HOLD pending focused investigation

The `linux-test` target was added to `makefile` (uncommitted — sits alongside
the user's pre-existing unrelated `open-github` diff) but `make linux-test`
does not currently exit 0, and the failure is a **hang**, not a triageable
test failure, so per this chunk's own TDD step 2 the work stops here rather
than pushing a fix.

**Evidence, two runs:**

1. **First run** (inside a fresh `swift:6.1` container): `swift test` hung
   27+ minutes, frozen immediately after logging that a trivial synchronous
   test (`NamedPipeChannelTests.testQueueStrategyEnum`, 3 assertions, no I/O)
   had "started" — no further output. Initial hypothesis: `NSLock`/cooperative
   thread-pool starvation in `NamedPipeChannel`'s async read-loop `Task`s.
   Never confirmed — tooling became unavailable mid-investigation. Separately,
   Docker Desktop's daemon was later found completely unreachable
   (`docker info`/`docker ps` couldn't connect to the socket at all), raising
   the possibility the "hang" was actually Docker Desktop itself crashing
   mid-run, not a code-level deadlock.
2. **Second run**, after restarting Docker Desktop and confirming the daemon
   healthy (`docker info` succeeding) for the *entire* run: `swift test` hung
   again — this time for 58 minutes, with **zero test output ever emitted**
   (not even the first "Test Suite started" line). Process inspection
   (`/proc/<pid>/status`, `/proc/<pid>/task/*/wchan`, `/proc/<pid>/fd`) showed:
   - `swift-test` (driver, pid 1, 5 threads): blocked in `rt_sigsuspend`
     (waiting on a child-process signal).
   - `FoundationToolsPackageTests.xctest` (bundle, pid 303, 2 threads):
     blocked in `poll()`/`ppoll`, **0:00 accumulated CPU time** after nearly
     an hour.
   - Both processes hold **both the read and write ends** of the same set of
     anonymous pipes (used for stdout/stderr capture between the driver and
     the bundle) — a pattern consistent with a pipe read blocking forever
     waiting for EOF that never arrives, because a stray writer fd is still
     open somewhere.
   - The hang occurs *before any of this repo's own test code runs* — it
     looks like it is inside the `swift-test` toolchain's own driver↔bundle
     IPC on Linux/aarch64, not obviously a defect in `NamedPipeChannel` or any
     other source in this repo. Not confirmed as a toolchain bug vs. an
     environment/image-specific issue (e.g. `swift:6.1` aarch64 base image,
     Docker Desktop's Linux VM networking/pipe emulation on macOS host) —
     needs a focused investigation, not a guess.

**Decision: ON HOLD.** Per user instruction, do not continue chasing this
inline — it needs a dedicated investigation session (e.g. reproduce outside
Docker Desktop's VM — a real Linux box or a different container runtime —
to isolate host-virtualization effects from a genuine toolchain/code bug;
attach `lldb` to a hung container before killing it, per-thread; try an
isolated single-test run instead of the full suite to see if the hang is
test-count/ordering dependent or immediate).

**State left behind:**
- `makefile`'s `linux-test` target: **uncommitted**, left in place (harmless,
  documents the intended target even though it doesn't yet pass).
- No test/source code changed for this chunk.
- Audit file: see §F11 for the corresponding finding.
- Nothing for this chunk has been committed.
