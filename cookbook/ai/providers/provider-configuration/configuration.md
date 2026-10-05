
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | identifier | freshly generated | Stable identity for a configuration instance. |
| `name` | string | none (required) | Caller-supplied display name; mutable after construction; no validation. |
| `pluginIdentifier` | string | none (required) | Identifies which plugin serves this configuration; not checked against any registry by this record. |
| `templateId` | string | none (required) | Identifies which provider template this configuration was created from; not checked against any registry by this record. |
| `base` (deriving a unique name) | string | none (required) | Candidate display name the caller wants made unique. |
| `taken` (deriving a unique name) | set of strings | none (required) | Names already in use that the returned name MUST avoid. |

