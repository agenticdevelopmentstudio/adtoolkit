
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `setting` | observed setting | — (required) | The setting whose live value is observed through an internally-created observer; visibility re-evaluates whenever this setting's value changes. |
| `child` | view | — (required) | The view shown or hidden based on the visibility predicate. Added as the sole content and pinned to the container's edges with no additional padding. |
| `isVisible` | predicate | — (required) | Predicate evaluated against the setting's current value, at construction and on every subsequent change, to decide whether the child view (and the container itself) is shown. |

