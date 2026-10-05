
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pluginManager` | a plugin manager | none (required) | Supplied when constructing the provider; the sole source of plugin descriptors, templates, and loaded plugin instances. |
| `model` | a chat-model descriptor | none (required) | The descriptor streaming a response is asked to route; only its id field is consulted. |
| `messages` | a list of chat messages | none (required) | The conversation history to send; mapped verbatim (minus name) to the plugin's own message list. |
| `justification` | an optional string | none (optional) | Free text from `options.justification` (`vscode.d.ts`); recorded to the log only, per **justification-recorded-only**. |
| `extensionIdentifier` | a string | none (required) | Identifies the calling extension for the justification log line; passed straight through with no validation. |
| saved provider-configuration list | a list of provider configurations, settings key `"aiplugin.configurations"` | `[]` | Read by listing available chat models and by resolving a configuration; observed by the configuration observer set up when the provider is constructed. |
| model catalog | a shared, loaded catalog | the loaded shared catalog | Consulted when building a descriptor for its context-window size; falls back to the default maximum input tokens (`4096`) when the model/template pair is unlisted. |

