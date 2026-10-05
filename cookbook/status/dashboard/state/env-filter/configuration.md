
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ENVIRONMENTS` | ordered list of 3 strings | `["production", "staging", "testing"]` | The complete selectable set, the default selection, and the allow-list hydration filters against. Changing it changes all three. |
| Storage key | string constant | `"adh-env-filter"` | The storage key read on creation and written on toggle. Not configurable by callers. |
| Persistent per-browser storage | ambient facility | platform-provided | Injected implicitly through the runtime; tests install their own implementation. |

Environment Filter takes no parameters and reads no environment variables or settings keys.

