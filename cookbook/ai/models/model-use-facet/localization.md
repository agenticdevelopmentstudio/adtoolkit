
`title` and `detail` are hardcoded, English-only literal strings returned
directly from a per-facet mapping — there is no localization-lookup
mechanism (a string catalog, a localized-string table) anywhere in this
component, so these ten menu labels and ten tooltips MUST ship in English
regardless of the host app's locale. The derivation's own evidence
vocabulary (the word-prefix and phrase lists) is likewise a fixed,
English-only token and phrase list; a model described only in another
language derives no facets from that description text (see Edge Cases).
This is a stated fact about the source, not a gap to resolve here.

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| *(none — inline literal)* | `Coding` / `Conversation` / `Problem solving` / `Research` / `Writing` / `Vision` / `Agents & tools` / `Translation` / `Speech & audio` / `Fast & low cost` | `title`: menu/checkbox label per facet |
| *(none — inline literal)* | `Writing, reviewing and debugging code` / … (one per facet) | `detail`: tooltip text per facet |

