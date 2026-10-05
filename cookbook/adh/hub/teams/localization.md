
- **Hardcoded English strings**: the identifier-validation operation's two
  messages — `"Identifier is required."` and `"Use reverse-domain form,
  e.g. com.example.platform."` — and the team client's create/update
  conflict-translation message, `A team with identifier "<identifier>"
  already exists.`, are fixed English literals in this domain's source.

No file in this domain defines an i18n key, a lookup table, or a locale
parameter — every user-facing string above is plain, fixed English. This is
a plain, honestly-reported fact about the current source, not a hidden gap
(see Compliance).

