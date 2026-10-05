
- A site whose full label does not start with the shared "Agentic Developer"
  prefix yields an empty lead and the whole label as the accent (via the
  shared title-split logic).
- An unknown site identifier (defensive, since the input is expected to be a
  valid site identifier) renders the identifier as the accent and omits the
  identity line.
- The tagline accepts arbitrary renderable content, so a consumer may pass a
  link or styled text; leaving it unset means "use the description," setting
  it explicitly to null means "omit."
- An empty-string tagline also omits the identity line, the same as null: the
  identity line is omitted whenever its resolved value is falsy, not only on a
  strict null comparison, so an empty string is treated as "omit" too.

