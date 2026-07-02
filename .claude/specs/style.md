# Style, Testing & File Naming

## Code Style

Configured via `.swift-format.json`. Run `make format` before committing.

- 4-space indentation, 120-character line length
- Break before each function argument
- File-scoped declarations: `private` (not `fileprivate`)
- No block comments — use `//` line comments or `///` doc comments
- No semicolons
- Triple-slash doc comments (`///`) for all public declarations

## Testing

- Tests organized by module: `FoundationTypesTests/`, `FoundationToolsTests/`, `FoundationCommonTests/`
- Framework: Swift Testing (`@Suite`, `@Test`, `#expect`)
- Always run with `swift test --no-parallel` to avoid concurrency issues
- `NamedPipeChannel` integration tests require environment variables — excluded by default

## File Naming Conventions

| Content | Path pattern |
|---|---|
| Core type | `spm/Sources/<Module>/TypeName.swift` |
| Extension | `spm/Sources/<Module>/Extensions/TypeName/TypeName+Feature.swift` |
| Protocol | `spm/Sources/<Module>/Protocols/ProtocolName.swift` |
| Test file | `spm/Tests/<Module>Tests/TypeNameTests.swift` |
