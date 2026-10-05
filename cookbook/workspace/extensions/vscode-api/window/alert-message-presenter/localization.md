
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `OK` | The single button title added when the request's item titles are empty. |
| (none — hardcoded literal) | `Cancel` | The title given the synthesized cancel-slot button whenever the button plan's cancel entry is absent. |

Both are literal English string constants, assigned with no localization lookup and no string-table entry, so the code presents them in English regardless of the user's system locale. The request's message, detail, and item titles are passed through verbatim from the caller and are not this component's own strings to localize.

