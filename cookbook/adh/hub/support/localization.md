
None of the seven given pieces route a string through a localization table
or resource key; every user-facing string below is a hardcoded English
literal:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no key) | `Not available in this version` | The shared "not available" message constant, the message every "not available" notice pane shows. |
| (none — literal, no key) | `Use lowercase letters, numbers and hyphens.` | The shared slug pattern's message, shown when a typed slug fails validation. |
| (none — literal, no key) | `Invalid JSON: ` | Prefix the JSON-parsing operation puts on the validation error it throws for malformed JSON, followed by the decoder's own description. |
| (none — literal, no key) | `—` | The display-formatting operation's default fallback value, shown for a missing or unparseable date unless the caller supplies its own. |

