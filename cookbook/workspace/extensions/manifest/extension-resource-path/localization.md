
This component produces exactly one user-facing string: the escape error's
description, a hardcoded English sentence with no localization lookup of
any kind — no locale parameter, no externalized string table entry. A
snippet-loading failure's reason and a theme-import failure's message (at
the component's call sites) both store this same English sentence
verbatim, for direct display to an extension author regardless of the
host's system locale.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — not externalized) | The path "declared value" resolves to "resolved value", which is outside the extension's own directory. | The escape error's description, shown to the extension author when a snippet, theme, theme `include`, or entry-point path escapes its extension's own directory. |

