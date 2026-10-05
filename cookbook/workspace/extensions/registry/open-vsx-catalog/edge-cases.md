
- **Null/empty input**: `{}` decoded as a search entry or as an extension
  detail MUST fail, because namespace, name, and version are required on
  both types. A `files` key present but empty (`{}`) MUST decode to an empty
  mapping, distinct from an absent `files` key, which MUST decode to nothing
  (open-vsx-catalog-003).
- **Boundary values**: `engines.vscode` absent and `engines.vscode` present
  as the empty string MUST both be treated as "not gated," yielding
  "installable" when nothing else refuses (open-vsx-catalog-013); an engine
  range string with a leading `>= ` (a space inside the operator, rather
  than immediately before a digit) MUST instead be treated as unreadable,
  because the engine-range grammar rejects interior whitespace
  (open-vsx-catalog-012). Parsing the empty string as a URL MUST resolve to
  nothing, so a `downloads["universal"]` entry of the empty string MUST
  behave identically to that key being absent — "no universal build."
- **Concurrent access**: the search entry, search page, extension detail,
  and installability verdict are concurrency-safe, side-effect-free values
  touching no shared mutable state; concurrent, independent decode or
  installability calls MUST NOT require external synchronization
  (**catalog-types-are-safe-for-concurrent-use**).
- **Error states**: A malformed required field (namespace, name, or
  version, on either a search entry or an extension detail) MUST sink the
  decode of the entry and, for a page, the whole page
  (open-vsx-catalog-008) — a visible failure. A malformed *optional* field,
  or a URL-shaped string that fails to parse, MUST instead resolve silently
  to nothing with no diagnostic value recorded anywhere in this concept —
  there is no equivalent, in this catalog, of the sibling manifest's
  decoding-failure record; the caller sees only an absence, indistinguishable
  from the key never having been sent (see Design Decisions).
- **Offline/disconnected state**: Not applicable — this concept performs no
  network or file I/O of its own; every type here operates purely on
  already-decoded fields or the input its caller already obtained, with no
  network, file-system, or process call anywhere in the catalog.

