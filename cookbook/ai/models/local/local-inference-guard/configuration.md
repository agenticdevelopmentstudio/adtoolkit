
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `catalog` (constructor parameter) | model catalog | production catalog | Injectable model-size lookup; tests substitute a fixed or failing fetcher. |
| `memory` (constructor parameter) | memory monitor | production monitor | Injectable RAM/pressure source; tests substitute a fixed value. |
| `deadline` (parameter to the exclusive-run operation) | duration | 600 seconds | Wall-clock bound on one exclusive operation's run. |
| `model`, `baseURL` (parameters to the verdict operation) | string, string | none — required | Identify the candidate local model and its loopback server. |
| `settings` (parameter to the verdict operation) | settings reader | none — required | Host-supplied reader for the `ai_guard_warn_pct` / `ai_guard_block_pct` override keys (declared on the model-fit policy, not this component). |
| `operation` (parameter to the exclusive-run operation) | the work to run | none — required | The local-inference work to run under the process-wide exclusive lock. |

The guard defines no environment variable of its own; the two settings keys
it reads (`ai_guard_warn_pct`, `ai_guard_block_pct`) are declared on the
sibling model-fit policy and reached only through the caller-supplied
settings reader.

