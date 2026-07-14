---
type: inventory
name: opencombine-usage-inventory
purpose: Evidence for the F10 migrate/keep decision on OpenCombine in FoundationTransactions
last_updated: 2026-07-13
semver: 0.1.0
author: Nicholas Bergantz
---

# OpenCombine Usage Inventory — `FoundationTransactions`

**Chunk:** [`07-opencombine-inventory`](../action-plan/07-opencombine-inventory.md)
**Audit finding:** [`2026-07-11-swift-audit.md` §F10](2026-07-11-swift-audit.md)
**Report-only** — no source changes. This document is the evidence base for
a future migrate/keep/hybrid decision on OpenCombine + OpenCombineDispatch.

## Method

Grepped `spm/Sources/FoundationTransactions/` for
`Publisher|Subject|sink|AnyCancellable|eraseToAnyPublisher|OpenCombine` plus
the Combine-family symbols named in the chunk spec
(`CurrentValueSubject|PassthroughSubject|@Published|.assign|.receive|.store(in:)`)
and the operator-chain symbols that would signal real migration cost
(`.map|.filter|.debounce|.combineLatest|.receive|.assign|Just|Empty|Future|.throttle|.merge|.zip|.removeDuplicates|.compactMap|.flatMap|Scheduler`).
Also checked `Package.swift` for how the dependency is wired, and the repo's
test target for any additional Combine surface.

Only 3 of the module's 7 files touch OpenCombine at all:
`Transaction.swift`, `TransactionHandler.swift`, `TransactionEvent.swift`
(the last only in a doc comment, no live symbol).

## Inventory

### `Transaction.swift`

| Line | Symbol | Usage |
|---|---|---|
| 2 | `import OpenCombine` | module import |
| 49 | `OpenCombine.CurrentValueSubject<TransactionState, Never>` | public stored property `statePublisher` |
| 52 | `OpenCombine.PassthroughSubject<TransactionResult, Never>` | public stored property `resultPublisher` |
| 58 | `OpenCombine.PassthroughSubject<TransactionEvent, Never>` | public stored property `eventPublisher` |
| 77 | `CurrentValueSubject(.pending)` | init |
| 78 | `PassthroughSubject()` | init |
| 79 | `PassthroughSubject()` | init |
| 87, 95, 103, 113, 125, 138, 150 | `statePublisher.send(...)` | state-change emission |
| 96, 104, 114, 126, 139, 151 | `resultPublisher.send(...)` | result emission |
| 115, 116, 127, 128, 140, 141, 152, 153 | `resultPublisher.send(completion: .finished)` / `eventPublisher.send(completion: .finished)` | terminal completion signal |
| 160 | `eventPublisher.send(event)` | solicited-event emission |

### `TransactionHandler.swift`

| Line | Symbol | Usage |
|---|---|---|
| 3–4 | `import OpenCombine`, `import OpenCombineDispatch` | module imports |
| 66–68 | `OpenCombine.AnyPublisher<ResourceState, Never>` / `resourceStateSubject.eraseToAnyPublisher()` | public computed property `resourceStatePublisher` |
| 123–124 | `OpenCombine.AnyPublisher<TransactionEvent, Never>` / `unsolicitedEventSubject.eraseToAnyPublisher()` | public computed property `unsolicitedEventPublisher` |
| 179 | `CurrentValueSubject<ResourceState, Never>` | private stored property `resourceStateSubject` |
| 180 | `PassthroughSubject<TransactionEvent, Never>` | private stored property `unsolicitedEventSubject` |
| 181 | `Set<AnyCancellable>` | private stored property `cancellables` — **dead code**: never populated (no `.store(in:)` call exists anywhere in the module; the only `.store(in:)` occurrences in the file are inside doc-comment examples at lines 46 and 121, illustrating how an external *consumer* would use it) |
| 220 | `CurrentValueSubject(initialState)` | init |
| 394 | `unsolicitedEventSubject.send(event)` | emission |
| 420 | `resourceStateSubject.send(state)` | emission |

`OpenCombineDispatch` is imported (line 4) but **no symbol from it is used** —
no `DispatchQueue` scheduler, no `.receive(on:)`/`.subscribe(on:)` call
anywhere in the module. This mirrors the F8 `depermaid` pattern (an unused
declared dependency) but at the import level within a used package; flagging
as a observation, not a new finding — out of scope for this report-only chunk.

### `TransactionEvent.swift`

| Line | Symbol | Usage |
|---|---|---|
| 10, 17 | `eventPublisher` / `unsolicitedEventPublisher` | **doc comment only** — no live Combine symbol; the type itself is plain `Codable`/`Sendable` with zero Combine dependency |

### Operator-chain search (negative result)

Grepped for `.map(|.filter(|.debounce(|.combineLatest(|.receive(|.assign(|Just(|Empty(|Future(|.throttle(|.merge(|.zip(|.removeDuplicates(|.compactMap(|.flatMap(|Scheduler` across all `FoundationTransactions` source files: **zero matches** on real operator chains. The only `.filter` hit is inside a doc-comment example (`TransactionHandler.swift:119`, illustrating `unsolicitedEventPublisher.filter { ... }` for a hypothetical consumer) — not executed by this module's own code.

### Test target

`spm/Tests/FoundationTransactionsTests/TransactionHandlerTests.swift`: **zero**
references to any Combine symbol. Tests exercise `TransactionHandler`/
`Transaction` purely through their non-Combine surface (state, submit,
process*, cancel). This means the module's own test suite does not even
subscribe to the publishers it exposes.

## Classification

| Bucket | Count | Detail |
|---|---|---|
| **Event-stream** | 13 usages | Every live (non-doc-comment) Combine call in the module is a bare emit/init on a `CurrentValueSubject`/`PassthroughSubject` — `.send(...)`, `.send(completion:)`, initializers. No operator is ever chained onto a publisher inside this module. This is a textbook notification-bus pattern: `statePublisher`, `resultPublisher`, `eventPublisher` (on `Transaction`) and `resourceStatePublisher`, `unsolicitedEventPublisher` (on `TransactionHandler`) each broadcast one event type with no transformation. All of it is a direct, mechanical fit for `AsyncStream<Element>` (`CurrentValueSubject` → `AsyncStream` + a stored "current value" property for the synchronous read that `resourceState`/`state` already provide separately; `PassthroughSubject` → plain `AsyncStream` with `.finish()` on terminal events). |
| **Operator-chain** | 0 usages | None found in source. The one `.filter` seen anywhere in the module is inside a doc-comment example, not executed code — it demonstrates what an *external consumer* could do with the exposed `AnyPublisher`, not something this module does internally. |
| **Public API surface** | 5 publisher properties | `Transaction.statePublisher`, `Transaction.resultPublisher`, `Transaction.eventPublisher` (all `public let`, concrete OpenCombine types — not even type-erased) and `TransactionHandler.resourceStatePublisher`, `TransactionHandler.unsolicitedEventPublisher` (public computed, type-erased to `OpenCombine.AnyPublisher`). `FoundationTransactions` is declared as its own SPM library product in `Package.swift:31-34`, so these are real, versioned public API — any external package/app depending on this product and subscribing via `.sink`/operators would break on a publisher→`AsyncStream` migration. No consumer of these five properties exists inside this repo (grepped the whole tree for the property/subject names — only the declaring files and doc comments match; `FoundationTransactionsTests` doesn't touch them at all), so the actual blast radius is unknown/external and can only be bounded by whoever owns downstream consumers of the `FoundationTransactions` product. |

**Total: 3 files touch OpenCombine, 24 live (non-doc-comment) symbol usages** (2 imports + 5 public property declarations/types + 3 private stored subjects + 1 dead `cancellables` set + 13 emit/init call sites), all falling into event-stream or public-API-surface; zero into operator-chain.

## Recommendation: **Hybrid — migrate the internals, keep (or dual-expose) the public surface for one deprecation cycle**

Rationale, in priority order (decision-framework: correctness → maintainability → simplicity → dependencies):

1. **Zero operator-chain usage** means there is no load-bearing reason to keep
   OpenCombine as an *implementation* detail. Every internal use is a plain
   broadcast — `AsyncStream` (or even a callback list) covers it with native
   `Task` cancellation and zero external dependency, directly answering F10's
   stated preference.
2. **`OpenCombineDispatch` is dead weight today** — imported, never used.
   Migrating removes it outright regardless of what happens to `OpenCombine`
   itself.
3. **The public API is the actual risk**, not the internals. `Transaction`'s
   three publisher properties are `public let` concrete types (not even
   `AnyPublisher`) — any signature change is source-breaking for consumers
   outside this repo, and this repo cannot see or grep those consumers. That
   argues against a silent breaking swap.
4. Given (1)+(2) push toward migrating and (3) argues for caution, a **hybrid**
   is the minimal-risk path: rebuild the internal event flow on `AsyncStream`,
   then either (a) re-derive the existing OpenCombine publishers from the
   stream as a thin, clearly-deprecated compatibility shim for one release, or
   (b) ship the `AsyncStream`-based API as a new set of properties alongside
   the existing publishers, mark the publishers `@available(*, deprecated)`,
   and drop them + the OpenCombine dependency in a subsequent major version
   once consumers have had a release to move.
5. **Keep-as-is is not recommended**: it leaves a dependency (plus its unused
   `OpenCombineDispatch` half) providing zero operator value, when the
   decision framework's dependency tie-breaker ("prefer the solution with
   fewer dependencies") is otherwise satisfied for free.

## Rough migration chunk estimate

For a future scope-plan, assuming the hybrid approach above:

1. **Chunk A** — add `AsyncStream`-based internal event plumbing to
   `Transaction` (replace `statePublisher`/`resultPublisher`/`eventPublisher`
   internals), with new tests exercising the stream directly.
2. **Chunk B** — same for `TransactionHandler`
   (`resourceStatePublisher`/`unsolicitedEventPublisher`).
3. **Chunk C** — deprecate the five OpenCombine-typed public properties
   (`@available(*, deprecated, message: "...")`), backed by the new streams,
   remove `OpenCombineDispatch` from `Package.swift` (already dead) and
   confirm the still-live `OpenCombine` dependency is only referenced from
   the now-deprecated shim surface.
4. **Chunk D** (future major version) — delete the deprecated OpenCombine
   properties and the `OpenCombine` package dependency entirely once
   downstream consumers have migrated.

**Estimate: 3 chunks now (A–C) + 1 deferred breaking-change chunk (D)** for a
complete migration; chunks A and B are independent and can run in parallel.
