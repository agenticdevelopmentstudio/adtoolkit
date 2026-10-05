
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | session configuration (opaque to this contract) | none — required at construction | Supplies the loader's own transport session's behavior (including any injected protocol handlers, cache policy, and timeout fields); the loader adds no timeout, retry, or backoff of its own on top of it. |
| `limit` | integer (bytes) | none — required parameter of every read-body call | The maximum number of bytes the returned body may contain; enforced both against the declared expected length and against the running total of bytes actually received. |

