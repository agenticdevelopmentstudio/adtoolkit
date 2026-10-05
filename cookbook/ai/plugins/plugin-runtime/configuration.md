
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| App name | text | — (required) | Passed when constructing the plugins coordinator / plugin manager; used to derive the per-app plugins search path under Application Support. |
| Additional search paths | list of locations | empty | Passed when constructing the plugins coordinator; extra directories the plugin manager scans for plugin bundles. |
| Plugin resolver | injected function returning an optional plugin, asynchronously | — (required) | Injected into the tool-calling chat session; resolves which plugin instance serves the next turn. |
| Context builder | injected function from message history to a chat request context, asynchronously | — (required) | Injected into the tool-calling chat session; builds the per-turn chat request context from the current history snapshot. |
| Event stream factory | injected function producing the plugin's response stream | runs the plugin transport with the given spec and plugin | Injected into the tool-calling chat session; the seam tests use to fake a plugin's response stream. |
| Tool source | optional injected tool source | none | Injected into the tool-calling chat session; when absent, the tool loop never runs even if the plugin emits tool-use events. |
| Registry | tool registry reference | — (required) | Passed to the MCP tool source; the source of active MCP servers and their tools. |
| Active server ids | set of identifiers | — (required) | Passed to the MCP tool source; a fixed snapshot of which servers' tools are exposed to the model. |
| `"aiplugin.configurations"` | list of provider configurations (settings key) | `[]` | The provider-configurations list — the ordered list of configured providers. |
| `"aiplugin.selectedConfigurationId"` | text (settings key) | `""` | The selected-configuration-id setting — empty means the daemon's zero-config Default path. |
| `"aiplugin.migratedToConfigurations"` | boolean (settings key) | `false` | The migration guard — one-time migration guard. |
| `"aiplugin.defaultConfigSeeded"` | boolean (settings key) | `false` | The default-seeded guard — one-time default-seeding guard. |
| `"aiplugin.config.<id>.field.<key>"` | text (settings key, secret-routed per field) | `""` | Per-configuration field value, via the per-configuration key logic / per-configuration store's field setting. |
| `"aiplugin.config.<id>.model"` | text (settings key) | template's resolved default model | Per-configuration selected model, via the per-configuration key logic. |
| `"aiplugin.<identifier>.field.<key>"`, `"aiplugin.<identifier>.model"`, `"aiplugin.selectedPlugin"` | text (legacy settings keys) | `""` | Read (never written) by migration via the legacy per-plugin config store; superseded by the per-configuration keys above. |

