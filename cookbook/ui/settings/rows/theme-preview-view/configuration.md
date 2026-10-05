
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | Color theme (optional) | none | Passed at construction; when given, the show operation is called immediately during initialization. When omitted, the view starts empty (empty-initial-state). |

The only other entry point is the public show operation, which fully tears
down and rebuilds the preview for a new theme (see Behavioral Requirements);
it is not a construction option and so is documented there rather than in
this table.

