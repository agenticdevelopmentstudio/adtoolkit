
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `query` (finding ranges, checking a match) | string | none — required | The search text; empty means "match nothing" for finding ranges and "match everything" for checking a match. |
| `text` (finding ranges) | string | none — required | The haystack scanned for the query; a caller passes a repository's name or a tree node's name. |
| `repo` (checking a match) | repository record | none — required | The candidate repository; only its name and path fields are read. |

This component reads no environment variable, settings key, or injected
dependency; the only configuration is the arguments supplied at each call
site.

