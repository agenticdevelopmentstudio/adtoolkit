
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `context` (parameter to building a request) | chat context | none — required | Conversation messages, model, token budget, tool specs, and the resolved configuration the caller supplies for one chat turn. |
| `config` (parameter to building a validation request) | plugin configuration | none — required | Resolved settings plus any injected secret (e.g. `apiKey`) the host wants the plugin to check for validity. |
| `status`, `body` (parameters to describing an error) | integer, raw bytes | none — required | The HTTP-style status code and raw response body from a chat request or validation request that failed. |

This contract defines no environment variable or settings key of its own; every value it reads arrives as a parameter already resolved by the host from the plugin's bundled descriptor schema (see the plugin-descriptor and plugin-configuration sibling components).

