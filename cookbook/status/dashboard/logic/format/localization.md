
The module holds no user-facing strings of its own; callers pass hardcoded English nouns (for example `"site"`, `"stale monitor"`, `"Vercel project"`). The module embeds one English-only rule:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — pluralization operation's default suffix) | `s` | Appended to the singular noun when no explicit plural is given and the count is not 1; English pluralization, not locale-aware. |

The count in the pluralization operation is rendered with default number-to-text conversion, not a locale-aware number formatter (plural-number-rendering).

