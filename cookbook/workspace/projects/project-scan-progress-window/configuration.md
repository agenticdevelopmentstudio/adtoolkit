
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| linger duration (internal constant) | duration (seconds) | `1.0` | Seconds finishing waits before closing the panel; not exposed to callers or configurable at the call site. |

Construction, presenting, and finishing take no parameters at all. There is
no caller-supplied configuration surface, environment variable, or settings
key anywhere here. The one caller-side wiring point lives outside this
component: the projects coordinator constructs a bare instance with no
arguments, presents it before starting a scan, and finishes it when the scan
completes.

