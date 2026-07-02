# History

## Unreleased

- Added `FoundationInterfaces` module — shared protocol definitions including `NormalizableDouble`/`NormalizableFloat` math protocols and `MessageSendable`/`MessageReceivable`/`MessageDuplex` pipe protocols
- Added `FoundationTransactions` module — generic transaction lifecycle management with OpenCombine publishers (`Transaction`, `TransactionHandler`, `TransactionalCommand`, state/result/error types)
- Added `NamedPipeChannel` to `FoundationTools` — Unix FIFO IPC channel conforming to `MessageDuplex`
- Added `OpenCombine` package dependency
