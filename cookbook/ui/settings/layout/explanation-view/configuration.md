
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | string | — (required) | The text rendered by the view's label; supplied at construction. |

**Usage notes**: The view provides no `update`/`setText` operation.
Callers that need to change the displayed text after construction SHOULD
assign the label's text directly — every call site in the codebase that
changes the view's text after construction does so this way. This is
guidance for how a caller chooses to update the view, not behavior the view
itself enforces or verifies, so no conformance test vector applies to it
(see Design Decisions).

