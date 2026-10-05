
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `roots` (construction parameter) | list of directory locations, optional | none given → the current user's home directory | Directories to scan; each is walked independently and results are combined. |
| `rootSkipPatterns` (construction parameter) | list of strings | the built-in default skip patterns | Glob patterns, matched case-insensitively, applied only to folder names found directly under a scan root. |
| `isCancelled` (scan parameter) | cancellation check | one that always reports "not cancelled" | Consulted once before each directory is processed; reporting "cancelled" stops the walk and returns results found so far. |
| `onProgress` (scan parameter) | progress callback, optional | none | Invoked once per visited directory with a running visited count, found count, and current path. |

This component itself reads no environment variable and no settings key.
The caller-side configuration point is a persisted skip-patterns setting
defaulting to the same built-in default skip patterns; a coordinating
component reads that setting's current value and passes it as the
`rootSkipPatterns` argument when it constructs a scanner — but that wiring
lives outside this component and is not part of its contract.

