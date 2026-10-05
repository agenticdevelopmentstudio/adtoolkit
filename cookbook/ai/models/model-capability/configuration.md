
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `capability` | capability type | — (caller-selected case) | The receiver of the reports check, or the case under test inside the has check / capabilities-of computation. |
| `capabilities` | array of strings | — (required) | Gateway-reported capability strings passed to the reports check, matched case-insensitively against the fixed spelling vocabulary. |
| `info` | resolved model | — (required) | The resolved model the reports check, has check, and capabilities-of computation inspect for capabilities, the tools flag, description, and "good for" text. |
| `extraText` | optional string | none | Additional prose (e.g. a local server's fetched blurb) folded into the text the use-facets computation derives `conversation` from; has no effect on `tools`, `reasoning`, or `vision`. |

