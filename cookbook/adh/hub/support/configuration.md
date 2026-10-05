
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| id, title, spec, values (parameters to building a form) | identifier string, title string, a field specification, a map of field values | none — required | Caller-supplied identity, title, field layout, and initial values for the built detail/state. |
| blockedReason (parameter to building a form) | optional string | absent | Propagated verbatim onto the built form state; not exercised further by any of these seven given pieces. |
| Markdown-editing injection point | an injectable markdown-editing collaborator | a plain-text implementation | Confined to a single execution context; read (never written) when constructing the built form's hosting view; the hosting app overwrites it once at launch with the real markdown module. |
| fallback (parameter to formatting a date for display) | string | `"—"` | Caller-suppliable placeholder text shown when the given ISO string is missing or fails to parse. |
| isolation (parameter to the closure-taking error normalizer) | an execution-context reference | the caller's own execution context | Not a value a caller ordinarily passes explicitly; documented here because it determines the execution context the body closure runs under — see Platform Notes. |

