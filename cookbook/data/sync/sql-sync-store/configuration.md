
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | database handle | required | The pool (or in-memory queue) holding every table; exposed read-only |
| `pullOnlyResources` | set of strings | `[]` | Resources that `stage` refuses with a `pullOnlyResource` error |
| `projection` | optional projection | none | Typed storage for the resources it claims; absent keeps every resource in JSON mirrors |
| `liveRows` `limit` | integer | `100` | Page size per call |
| `liveRows` `offset` | integer | `0` | Rows skipped per call |
| Database deadlines | duration | read 10 s, write 60 s | Set on the injected database, not on the store |

No environment variables or settings keys are read.

