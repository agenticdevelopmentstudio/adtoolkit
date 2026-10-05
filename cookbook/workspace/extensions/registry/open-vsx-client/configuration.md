
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `registryBase` | `URL` | `OpenVSXClient.openVSXRegistry` (`https://open-vsx.org/api`) | Base URL of the Open VSX-compatible registry API; overridable to address a self-hosted instance. |
| `session` | `URLSession` | `.shared` | Only its `configuration` is read, to construct the internal `BoundedBodyLoader` — in particular any injected `protocolClasses`. |
| `maximumArtifactBytes` | `Int` | `OpenVSXClient.defaultMaximumArtifactBytes` (536,870,912) | Ceiling on the bytes `data(at:)`/`text(at:)` will read before throwing `artifactTooLarge`. |
| `maximumMetadataBytes` | `Int` | `OpenVSXClient.defaultMaximumMetadataBytes` (8,388,608) | Ceiling on the bytes `search`/`detail` will read before throwing `responseTooLarge`. |
| `query` (`search` parameter) | `String` | `""` | Free-text search term; empty means browse the whole catalog. |
| `offset` (`search` parameter) | `Int` | `0` | Row offset into the result set. |
| `size` (`search` parameter) | `Int` | `OpenVSXClient.defaultPageSize` (50) | Rows requested per page. |
| `sortBy` (`search` parameter) | `SortOrder` | `.downloadCount` | One of `downloadCount`, `relevance`, `rating`, `timestamp`. |
| `version` (`detail` parameter) | `String?` | `nil` | Named version to address; `nil` addresses the latest published version. |

