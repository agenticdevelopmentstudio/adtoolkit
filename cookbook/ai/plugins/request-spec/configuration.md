
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Transport kind | transport-kind value | none — required | The HTTP or command description of how to reach the provider for this request. |
| Timeout | numeric duration | 120 | Wall-clock budget for the whole request before the host cancels it. |
| Method | method value | POST | HTTP method for an HTTP-transport request. |
| Headers | text-keyed map of text | empty | HTTP header fields applied to the request. |
| Body | optional byte payload | none | HTTP request body. |
| Executable location | location | none — required | Path to the executable the host spawns as a subprocess. |
| Arguments | list of text | empty | Command-line arguments passed to the subprocess. |
| Standard input | optional byte payload | none | Bytes written to the subprocess's standard input before it is closed. |
| Environment | text-keyed map of text | empty | Environment variables for the subprocess; a non-empty value replaces the host's own environment for the child (see environment-replace-semantics). |

This type defines no environment variable or settings key of its own; every
value above arrives as a caller-supplied constructor argument.

