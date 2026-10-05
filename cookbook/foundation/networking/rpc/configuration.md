
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| executable path | string (file path) | none — required | The child executable to launch. |
| arguments | list of strings | `[]` | Arguments passed to the child. |
| environment | key-value map of strings | `{}` | Environment variables applied per environment policy. |
| environment policy | enumeration (replace / merge-over-parent) | replace | See environment-replace-policy / environment-merge-policy. |
| framing | enumeration (newline-delimited / content-length-prefixed / unframed) | newline-delimited | How the child's standard output is split into frames; ignored by the one-shot run operation, which forces unframed. |
| working directory | string (file path), optional | none (inherit the parent's) | The child's working directory. |
| budget (parameter to the one-shot run operation) | number (seconds) | none — required | The wall-clock bound for the whole one-shot run. |
| maximum frame bytes (internal constant, not configurable) | integer (bytes) | `16777216` (16 MiB) | Per-frame buffering cap for the newline-delimited and content-length-prefixed schemes. |
| read chunk size (internal constant, not configurable) | integer (bytes) | `65536` (64 KiB) | High-water mark for both the standard-output pump and the standard-error drain. |
| termination grace seconds (internal constant, not configurable) | number (seconds) | `2.0` | Graceful-signal grace period before escalating to the forceful signal. |
| standard-error drain grace seconds (internal constant, not configurable) | number (seconds) | `0.5` | Bounded wait for the standard-error drain when reading standard-error text or bytes. |
| message-pump drain grace seconds (internal constant, not configurable) | number (seconds) | `0.5` | Bounded wait, during termination, for the standard-output pump to flush and finish. |
| maximum standard-error bytes (internal constant, not configurable) | integer (bytes) | `1048576` (1 MiB) | Tail-retaining cap on the buffered standard-error capture. |
| maximum wall-clock budget seconds (internal constant, not configurable) | number (seconds) | `31536000` (one year) | The ceiling above which a budget is treated as "no deadline" rather than converted to a trapping zero-duration wait. |

