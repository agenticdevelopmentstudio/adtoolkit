
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ENDPOINT_KINDS` | `readonly ["http", "frontend", "admin", "health", "custom", "dns"]` | compiled in | The vocabulary itself. Changing it means editing the source. |
| `NON_DEPLOY_KINDS` | `ReadonlySet<string>` | `{"health", "custom", "dns"}`, from the engine | Supplied by `@agentic-toolkit/deploy-platform/engine`. |
| `k` (argument to `isEndpointKind`) | `string` | none (required) | The candidate kind string to test. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. Its one import is the re-export from `@agentic-toolkit/deploy-platform/engine`.

