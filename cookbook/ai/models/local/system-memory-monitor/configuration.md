
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Constructor parameters | — | none | The constructor takes no parameters; there is nothing for a caller to configure at construction time. |
| Event set (internal) | set of memory-pressure events | `{normal, warning, critical}` | Hardcoded at construction; not exposed for a caller to narrow or widen. |
| Event queue label (internal) | string | `"aipluginkit.memory-pressure"` | Hardcoded at construction; not exposed as a parameter. |
| Monitoring interface (injection seam) | interface | the shared instance (at each consumer's own call site, e.g. an inference guard's constructor) | Consumers depend on the interface, not the concrete type, so a test or alternate host MAY substitute a fixed-value conformer. |

This component reads no environment variable and no settings key of its
own.

