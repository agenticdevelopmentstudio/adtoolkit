
A note's detail, and the raw-text fallbacks it quotes, are shown to a
person rather than swallowed — this component's own documented intent
says so directly ("what was compromised is shown to a person rather than
swallowed") — but every one of those strings is composed as a hardcoded
English literal (e.g. "already declared by an earlier section; this
declaration is ignored", "section {index} declared no title; using
\"{fallbackTitle}\""); none is looked up through a localization catalog or
key. An option's label that falls back to a member's raw value (per
`enum-label-positional`) is similarly whatever text the extension manifest
happened to write, never localized by this component.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — no localization key exists) | e.g. "already declared by an earlier section; this declaration is ignored" | A note's detail, composed inline in English at each point classification records one |

