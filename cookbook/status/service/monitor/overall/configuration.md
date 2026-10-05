
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Per-endpoint list (input to the base rollup) | a list of health values | none — required | The per-endpoint health verdicts to roll up into one overall status. |
| Per-endpoint list (input to the public headline fold) | a list of health values | none — required | The same per-endpoint health verdicts, passed unchanged into the base rollup. |
| Non-endpoint-problem flag (input to the public headline fold) | boolean | none — required | Whether the caller has an open non-endpoint problem (e.g. a failed build or an unreachable platform API) to fold into the public headline. |

Neither operation reads an environment variable, a settings key, or an injected dependency; both take their entire input as direct arguments, and this module imports nothing at runtime beyond the health vocabulary's type.

