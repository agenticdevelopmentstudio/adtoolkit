
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| settings | settings-reader function (concurrency-safe, key → optional text) | none (required) | Injected by the caller on every call; the sole source of registry, selection, and model data. |
| id | configuration identifier | none (required for model lookup) | The configuration identifier whose stored model is being looked up. |
| Configurations key | text (constant, `"ai_configurations"`) | n/a | Settings key the configurations lookup reads for the JSON-encoded configuration-list registry. |
| Selected-configuration-id key | text (constant, `"ai_selected_config_id"`) | n/a | Settings key the selected-configuration lookup reads for the selected configuration's identifier string. |
| Model key (per configuration) | text (per-configuration, `"aiplugin.config.<id>.model"`) | n/a | Settings key the model lookup reads for that configuration's stored model. |

