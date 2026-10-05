
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `systemPrompt` | text | none — required | System prompt text for this one-shot turn |
| `userPrompt` | text | none — required | The single user message's text |
| `maxTokens` | integer | none — required | Forwarded unvalidated into the request context's `maxTokens` field on the plugin path; unused on the CLI path |
| `cliModel` | text | `"haiku"` | Model name for the CLI path only; an empty string is also treated as `"haiku"` by the CLI path |
| `timeout` | duration (seconds) | `defaultTimeout` (`60`) | Governs only the CLI path's subprocess wait; ignored on the plugin path |
| `settings` | settings-reader interface | none — required | Reads the host's synced provider-registry values, keyed by the provider-config-keys scheme |
| `runtime` | plugin runtime interface | live implementation | Injectable plugin-load/run seam |
| `cliRunner` | CLI runner interface | live implementation | Injectable CLI-subprocess seam |
| `secretStore` | secret store interface | Keychain-backed on Apple platforms | Source of a template's secret field values |
| `inferenceGuard` | local-inference guard (optional) | shared instance | The local-inference RAM guard; opting out disables both checkpoints |

This component reads settings keys under the provider-config-keys scheme, via the provider resolver and the plugin path: the configurations registry, the selected-configuration id, a configuration's stored model, its non-secret fields ledger, and each ledger field's stored value.

