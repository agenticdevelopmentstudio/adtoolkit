
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | "Show the whole message" | The toggle's label/tooltip when collapsed; a private string literal in the source, not sourced from a resource file |
| (none — hardcoded) | "Show less" | The toggle's label/tooltip when expanded; same as above |
| (none — hardcoded) | "…" | Appended after truncated text; same as above |

The two toggle titles are private string literals assigned directly to the platform's own label, description, and tooltip mechanisms (see Platform Notes); the source never looks either one up in a string table, so both always render in English regardless of the user's locale.

