
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `schemaVersion` | integer | `currentSchemaVersion` (`3`) | The descriptor's descriptor-schema version; unvalidated by this concept (see Edge Cases). |
| `identifier` | string | none (required) | The descriptor's unique plugin id. |
| `displayName` | string | none (required) | The descriptor's human-readable name; also the implicit template's `displayName`. |
| `version` | string | none (required) | The descriptor's plugin version string, unvalidated. |
| `models` | list of strings | `[]` | The descriptor's model identifiers, rendered as a popup. |
| `defaultModel` | string, optional | absent | The descriptor's preselected model; falls back to the first entry of `models` when resolved. |
| `fields` | list of fields | `[]` | The descriptor's settings fields the host renders and persists. |
| `templates` | list of provider templates, optional | absent | The descriptor's explicit provider presets; absent/empty synthesizes one implicit template. |
| `key` | string | none (required) | A field's config-bag lookup key and persisted-setting suffix. |
| `label` | string | none (required) | A field's host-rendered label. |
| `kind` | field kind (`secret` or `text`) | none (required) | A field's storage classification. |
| `placeholder` | string, optional | absent | A field's optional placeholder text. |
| `id` | string | none (required) | Per-model detail's model-id key. |
| `description` | string, optional | absent | Per-model detail's one-line model description. |
| `tools` | boolean, optional | absent | Per-model detail's tool/function-calling support flag. |
| `goodFor` | string, optional | absent | Per-model detail's "well-suited for" blurb. |
| `id` | string | none (required) | A provider template's preset id. |
| `displayName` | string | none (required) | A provider template's preset display name. |
| `defaultValues` | map of string to string | `{}` | A provider template's seeded config values injected before request-building. |
| `models` | list of strings | `[]` | A provider template's model list. |
| `defaultModel` | string, optional | absent | A provider template's preselected model. |
| `secretRequired` | boolean | `true` | A provider template's flag for whether a secret field must be filled. |
| `fields` | list of fields, optional | absent | A provider template's field overrides; absent inherits the descriptor's `fields`. |
| `provider` | string, optional | absent | A provider template's vendor name; falls back to `displayName` when resolved. |
| `llm` | string, optional | absent | A provider template's model-brand label; falls back to the empty string when resolved. |
| `configType` | string, optional | absent | A provider template's auth-method label; falls back to `"API Key"`/`"Local"` when resolved. |
| `providerDescription` | string, optional | absent | A provider template's vendor blurb for the details pane. |
| `llmDescription` | string, optional | absent | A provider template's model-family blurb for the details pane. |
| `modelDetails` | list of per-model detail, optional | absent | A provider template's per-model descriptive metadata. |

