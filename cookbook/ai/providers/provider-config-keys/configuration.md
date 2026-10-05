
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Configuration identifier | identifier | none (required) | The configuration identifier passed to the field-key, model-key, secret-fields-key, and fields-key operations; embedded verbatim in its canonical string form in every per-configuration key. |
| Field name | text | none (required) | The descriptor field's key (e.g. `"apiKey"`, `"baseURL"`), passed to the field-key operation; caller-supplied and unvalidated (see Edge Cases). |
| Selected-configuration-id key | text (constant) | `"ai_selected_config_id"` | Fixed settings key holding the id of the configuration used for AI summaries; an empty stored value means the daemon's zero-config path. |
| Configurations key | text (constant) | `"ai_configurations"` | Fixed settings key for the daemon's registry index: a JSON-encoded list of provider configurations. |
| Enabled key | text (constant) | `"ai_summaries_enabled"` | Fixed settings key for the AI-summaries-enabled flag. |
| Legacy-cleaned key | text (constant) | `"ai_legacy_cleaned"` | Fixed one-time-guard key marking that legacy plugin-keyed AI settings have already been cleaned up. |

