
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `contributionKey` | `String` | none — required, declared by each conformer | The manifest key this point consumes, e.g. `"themes"`; diagnostics only. |
| `contributions` | `ExtensionManifest.Contributions` | none — required, supplied by the caller to `apply` | The extension's decoded contribution data; `.empty` when its manifest has no `contributes` key. |
| `manifest` | `ExtensionManifest` | none — required, supplied by the caller to `apply` | The extension's full decoded manifest. |
| `directory` | `URL` | none — required, supplied by the caller to `apply` | The extension's own installed folder; manifest-relative paths resolve against it. |
| `extensionIdentifier` | `String` | none — required, supplied by the caller to `withdraw` | The identifier of the extension whose contributions to remove. |
| `Payload` | generic type parameter | none — chosen by the owner of a `ContributionRegistrations` instance | What one applied extension's registration records; unconstrained. |
| `Note` | generic type parameter constrained to `ExtensionContributionNote` | none — chosen by the owner | The note type this registration collection keeps alongside each payload. |

