
This component *is* the localization mechanism, not a consumer of one — it
has no fixed strings of its own to enumerate in a key/default/context table.
Instead, it implements the lookup an extension's own `%key%` placeholders
resolve through:

| Table filename | Applies when | Precedence |
|----------------|--------------|------------|
| `package.nls.json` | Always searched | Least specific — the fallback for any key a more specific table lacks |
| `package.nls.<language>.json` | The locale's language code resolves | Overrides the default table for keys it also defines |
| `package.nls.<language>-<region>.json` | The locale's region also resolves | Most specific — overrides both tables above for keys it also defines |

Matching against the filenames on disk is case-insensitive. Each table's
entries decode in either of two shapes VS Code's ecosystem uses today: a
bare string, or an object with a `message` string field and an ignored
`comment` array meant for a human translator. A manifest value is a
reference only when it is *entirely* one `%key%` token; a key with no
matching entry is left visible on screen exactly as VS Code leaves it,
rather than resolved to an empty string.

