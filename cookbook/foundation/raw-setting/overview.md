
Reads a setting stored as text, such as a settings-table row or an environment variable, into the value it means, falling back to a default for anything absent or malformed. It is one set of rules so the same garbage string never reads true in one feature and false in another. Booleans accept a fixed set of spellings, integers are clamped into an allowed range, and strings are trimmed and fall back when empty.

