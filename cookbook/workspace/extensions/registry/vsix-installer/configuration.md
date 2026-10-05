
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installDirectory` | `URL` | none (required) | Where installs land and are scanned for superseded copies; injected rather than derived. |
| `hostVersion` | `SemanticVersion` | `ExtensionRegistry.declaredVSCodeVersion` (`1.138.0`) | The VS Code engine version an archive's `engines.vscode` range is checked against. |
| `fileManager` | a shareable closure returning a file-system handle | the platform's default file-system handle | File-system seam; a test substitutes a handle that refuses a named move or removal. |
| `detail` (`install(_:using:)` parameter) | `OpenVSXExtensionDetail` | none (required) | The registry record naming the version, its download URL, and its verification artifacts. |
| `client` (`install(_:using:)` parameter) | `OpenVSXClient` | none (required) | How the archive and verification artifacts are fetched from the registry. |
| `archive` (`install(archive:...)` parameter) | `Data` | none (required) | The `.vsix` bytes already in hand. |
| `verification` (`install(archive:...)` parameter) | `VSIXVerification` | none (required) | What the bytes were already proved to be, computed by `VSIXArchive.verify` before this call. |
| `expectedIdentifier` (`install(archive:...)` parameter) | `String?` | `nil` | The identity a registry source claimed for the archive; `nil` when there is no claim to check (a user-supplied file). |
| `source` (`install(archive:...)` parameter) | `VSIXInstallation.Source` | none (required) | Whether this installation's provenance is recorded as `.registry` or `.localFile`. |

