
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `customerID` | string | none — required | Tenant-scoping value bound into every row; the store never substitutes a default, since an empty string is a value, not an absence. |
| `ecosystemID` | string | none — required | Same as `customerID`, scoping every row within one ecosystem. |
| `path` | file path (string) | resolves under one token-named directory by default | Overridable per store initialization; the default keeps this store and any other consumer of the same token on one database file and its write-ahead-log state. |
| `token` | string | caller-supplied | Selects the token-named directory the default path resolves under. |

