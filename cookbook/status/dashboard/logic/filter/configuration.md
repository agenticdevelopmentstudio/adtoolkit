
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `haystack` | a text value | none (required) | The text searched. At the call site this is the row's search text: the row's name, environment, status word, detail and commit body joined with spaces. |
| `query` | a text value | none (required) | The user's free-text query. Trimmed, lowercased and split on whitespace into AND-ed tokens. A blank value matches everything. |

The operation reads no environment variables, settings keys or injected dependencies.

