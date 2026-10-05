
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rootURL` | file location | required, set at construction | The directory this coordinator syncs and watches. |
| `config` | configuration value | required; caller may pass the well-known default | Opaque-package extensions/display names and the storage key for custom file-type mappings — threaded through but not read by this model beyond `packageExtensions`. |
| `excludedPrefixes` | list of path prefixes | required, set at construction | Absolute path prefixes; change notifications at or under any of them are dropped by the exclusion check before the change-handling routine ever runs. |
| `ignorePatterns` | list of glob patterns | `[]` | Wildcard filename patterns filtered out of every directory listing; settable at any time through the coordinator's public property. |
| `packageExtensions` | set of extensions | `[]` (via the configuration value) | Extensions whose matching directories are treated as opaque, single-item packages. |
| `packageDisplayNames` | mapping of extension to display name | `[:]` (via the configuration value) | Passed through the configuration value; not read by this model itself. |
| `customMappingsDefaultsKey` | string | `"AgenticFileBrowser.customMappings"` (via the configuration value) | Storage key naming; not read by this model itself — owned by the custom file-type mapping table. |
| `onChange` (start watching) | optional no-argument callback | `nil` | Callback the coordinator invokes after every applied sync or watched change. |
| `url` / `isDirectory` / eager-load flag (node construction) | file location / boolean / boolean | eager-load flag defaults to `false` | Per-node construction arguments the coordinator and the one-level directory read operation supply. |

