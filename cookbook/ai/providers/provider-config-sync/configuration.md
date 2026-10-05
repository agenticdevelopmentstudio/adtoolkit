
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | none (required) | The sync envelope's flag for whether AI summaries are enabled. |
| `selectedConfigId` | optional identifier | none (required; pass absent for no selection) | The sync envelope's pointer to the configuration used for summaries; absent is the documented zero-config path. |
| `configs` | list of resolved-configuration records | none (required) | The sync envelope's full set of configured providers, fully resolved. |
| `id` | identifier | none (required) | The resolved-configuration record's identity, matching the app-side configuration's own identifier that it mirrors. |
| `name` | text | none (required) | The resolved-configuration record's display name. |
| `pluginIdentifier` | text | none (required) | The resolved-configuration record's plugin-bundle identifier. |
| `templateId` | text | none (required) | The resolved-configuration record's provider-template identifier. |
| `model` | text | none (required) | The resolved-configuration record's resolved model string. |
| `values` | text-to-text map | none (required) | The resolved-configuration record's non-secret resolved field values, keyed by field key. |
| `secrets` | text-to-text map | none (required) | The resolved-configuration record's secret resolved field values, keyed by field key; an empty value means "clear this credential." |

