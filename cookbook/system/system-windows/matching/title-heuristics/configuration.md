
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` (input to the pattern-extraction / fingerprint operations) | text | — (required) | The raw window title supplied by the caller (the window list's title for the window). |
| separator list | an ordered list of separator strings | `[" — ", " – "]` | Title separators, most specific first; a constant, not caller-configurable. |
| recommended strategy | strategy value | app-and-title-substring (Terminal heuristic: app-only) | Strategy stored in fingerprints produced by each heuristic; fixed per type. |
| app-names | list of text | per heuristic (see identity requirements) | Owning-app names the registry maps to the heuristic; fixed per type. |

The heuristics take no construction parameters, read no environment
variables or settings keys, and have no injected dependencies.

