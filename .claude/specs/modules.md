# Module Reference

## FoundationTypes

Core SIMD-optimized mathematical types (`SIMD2<T>`, `SIMD3<T>`, `SIMD4<T>` storage).

**Basic Types:**
- `Complex<T>` — complex numbers (2D); typealiases: `ComplexDouble`, `ComplexFloat`
- `Position<T>` — 3D coordinates with cylindrical/spherical conversions; typealiases: `FloatPosition`, `DoublePosition`
- `Quaternion<T>` — 3D rotations; axis-angle, Euler, and ISO spherical initializers; typealiases: `FloatQuaternion`, `DoubleQuaternion`
- `SpatialPose<T>` — combined Position + Quaternion
- `NumericSign` — `.positive`, `.negative`, `.zero`

**Waveform Types (uniformly sampled time-series):**
- `Waveform1D<T, U>` — 1D signal with `values`, `dt`, `t0`; methods: `duration`, `durationInSeconds()`, `samplingFrequencyInHz()`, `nyquistFrequencyInHz()`, `sampleCount`
- `WaveformPosition<T>`, `WaveformQuaternion<T>`, `WaveformSpatialPose<T>` — same shape for spatial types

**Precision Time Types:**
- `PrecisionTimestamp` — attosecond (10⁻¹⁸ s) resolution; properties: `interval`, `timescale`, `referenceFrame`, `uncertainty`, `seconds`, `attoseconds`, `daysSinceEpoch`, `secondsOfDay`
- `PrecisionTimeInterval` — `SIMD2<UInt64>` storage `[seconds, attoseconds]`; sign via `NumericSign`
- `Timescale` — `tai`, `tt`, `tcb`, `tdb`, `utc`, `gps`, `ut1`, `tcg` (default: `.tai`)
- `ReferenceFrame` — `earthCenter`, `solarSystemBarycenter`, `topocentric`, `heliocentric`, `lunarCenter` (default: `.earthCenter`)

**Type parameter constraint:** `T: BinaryFloatingPoint & SIMDScalar & Sendable & Codable`

**File layout:**
- Core definitions in `spm/Sources/FoundationTypes/`
- Extensions in `Extensions/TypeName/TypeName+Feature.swift`
- Extension categories: `BaseExtensions`, `Codable`, `Normalization`, `Arithmetic`, `RotationMatrixElements`, `Comparable`
- Error types in `Support/`: `TimestampError`, `WaveformCodingError`, `WaveformError`

---

## FoundationTools

- `PersistenceStorage` (actor) — type-safe persistent storage; `UserDefaults` on macOS, JSON file (`~/.persistant_storage_config.json`) on Linux; singleton via `.shared`; generic keys via `PersistenceKey<T: Codable & Sendable>`
- `NamedPipeChannel` — Unix FIFO IPC; creates `/tmp/<name>_in` and `/tmp/<name>_out`; conforms to `MessageDuplex`; queue strategies: `fifo`, `lifo`, `roundRobin`; integration tests require env vars (excluded by default)

---

## FoundationInterfaces

Shared protocols with no external dependencies.

**Math** (`Math/Normalizable.swift`):
- `NormalizableDouble`, `NormalizableFloat` — separate protocols (not a single generic) to avoid SIMD+generics Swift compiler conflicts
- Both define: `normalize()`, `normalized`, `magnitude`, `magnitudeSquared`, `isUnit`, `isNormalized`

**Pipes** (`Pipes/`):
- `MessageSendable` — `send(_: Data)`, `send(_: String)`
- `MessageReceivable` — inbound (stub)
- `MessageDuplex` — composition of both; conformed to by `NamedPipeChannel`

---

## FoundationTransactions

Generic transaction lifecycle management using OpenCombine publishers.

- `Transaction<Command: TransactionalCommand>` (class, `@unchecked Sendable`)
  - Lifecycle timestamps: `createdAt`, `sentAt`, `acknowledgedAt`, `completedAt`
  - Publishers: `statePublisher: CurrentValueSubject<TransactionState, Never>`, `resultPublisher: PassthroughSubject<TransactionResult, Never>`, `eventPublisher: PassthroughSubject<TransactionEvent, Never>`
  - Helpers: `isTerminal`, `isTimedOut`, `elapsedSinceSent`
- `TransactionalCommand` — protocol: `commandType: TransactionConcurrency`, `timeout: Double?`
- `TransactionState` — `.pending`, `.awaitingAck`, `.executing`, `.queued`, `.completed`, `.failed`, `.cancelled`, `.timedOut`
- `TransactionResult` — `.acknowledged(transactionID:)`, `.completed(transactionID:response:)`, `.failed(transactionID:error:)`, `.timedOut(transactionID:)`, `.queued(transactionID:position:)`
- `TransactionError` — `resourceNotReady`, `categoryConflict`, `acknowledgmentTimeout`, `responseTimeout`, `resourceError`, `communicationLost`, `cancelled`, `unknown`
- `TransactionConcurrency` — concurrency category enum
- `TransactionEvent` — event data emitted during execution
- `TransactionHandler` (actor) — manages transaction queue and state machine
- `ResourceState` — resource availability/readiness enum

---

## FoundationCommon

Base utilities — currently a placeholder (`FoundationCommon/Placeholder.swift`).
