
Nothing in this scope references a string-key or localization table; every
user-facing string is a hardcoded English literal composed inline:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none - literal, no key) | `Nothing here yet` | A level's empty-state message default. |
| (none - literal, no key) | `This cannot be undone.` | The delete action's documented fallback confirmation message when none is set (the display of this text is outside this engine's own scope). |
| (none - literal, no key) | `<label> is required` | The validator - required text, select, number, date, and string-set fields. |
| (none - literal, no key) | `<label> has an invalid format` | The validator's default pattern-mismatch message. |
| (none - literal, no key) | `<label> must be one of the listed options` | The validator's select-field membership check. |
| (none - literal, no key) | `<label> must be a whole number` | The validator's integer check. |
| (none - literal, no key) | `<label> must be at least <value>` / `<label> must be at most <value>` | The validator's numeric bounds check. |
| (none - literal, no key) | `<label> must be valid JSON` | The validator's JSON-field parse check. |

