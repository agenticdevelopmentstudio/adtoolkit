
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Request specification | request specification value | none — required | Describes the HTTP or subprocess request to perform, including its wall-clock timeout (see the sibling request specification recipe). |
| Plugin | plugin reference | none — required | Supplies a fresh decoder for turning response bytes into stream events, and an error-description operation for translating a failure into a human-readable message (see the sibling plugin recipe). |

This component defines no environment variable and no settings key of its
own; every value it operates on arrives as one of the two parameters above,
ultimately sourced from the request specification the caller supplies.

