
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Sections (set via the grouped or flat setter) | A list of sections (each with an optional title and items) | Empty | Full sectioned row model; the grouped setter groups rows with headers per non-empty section title, the flat setter wraps items in one untitled section. |
| Selection callback | A callback receiving the newly selected item, or none | none | Invoked with the newly selected item, or none, on a user-driven selection change; never invoked for a programmatic change made through selecting by id or a theme-triggered reload. |
| Title | An optional string | none | Text shown in the optional header above the list, set via the title setter; empty or unset hides the header unless a header accessory view is set. |
| Footer view | An optional view | none | Client view pinned below the list via the footer setter, spanning the sidebar width; unset collapses the footer to zero height. |
| Header accessory view | An optional view | none | Client view shown directly beneath the title and above the list via the accessory setter, spanning the header's width; unset collapses to nothing. |

