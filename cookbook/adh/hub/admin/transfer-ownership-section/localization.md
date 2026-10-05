
Not applicable: no translation-function call or string-table lookup is present; every
user-facing string (disclosure title, body copy, dialog title/description, button labels, error
fallbacks) is a literal, hardcoded string.

The lowercased form of `entityNoun` used in inline prose is a casing transform, and casing is
locale-sensitive — a lowercase conversion can change meaning or produce the wrong result in some
locales (e.g. Turkish `I`/`ı`). This is a display transform of caller-supplied text, not an
invariant-culture-style identifier normalization, so it MUST use the user's locale, never an
invariant/ordinal casing call.

