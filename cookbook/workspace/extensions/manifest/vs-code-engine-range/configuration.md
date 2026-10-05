
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the string passed to `init?(_:)` | `String` | none (required) | The raw `engines.vscode` value read from a manifest's `package.json`; the sole input this component accepts. |
| `version` passed to `accepts(_:)` | `SemanticVersion` | none (required) | The host (or candidate) version the range is evaluated against; every production caller passes `ExtensionRegistry.declaredVSCodeVersion` (`1.138.0`). |

There are no environment variables, settings keys, or injected
dependencies: `VSCodeEngineRange` takes every input as a plain initializer
or method argument and reads no ambient state.

