
- **Empty text, no capabilities.** Deriving facets from an empty string and
  empty capabilities (the default) MUST return an empty set — zero words
  are produced by tokenizing an empty string, and empty capabilities report
  nothing.
- **Text with no letters or numbers.** Deriving facets from a string with no
  letters or numbers (e.g. `"--- ... !!!"`) MUST return an empty set —
  tokenization on "not a letter and not a number" yields zero words, and
  phrase matching finds no substring hits either.
- **Unrecognized capability string.** A capabilities list containing a
  string the capability-matching check does not recognize for any facet
  (e.g. `"beta-feature"`) MUST be silently ignored — it implies no facet and
  MUST NOT raise an error.
- **Boundary: single matching character run.** A word that is exactly one of
  a facet's prefixes (e.g. the word `"cod"` alone) MUST count as evidence —
  a word matching itself as its own prefix; this is the minimum-length case
  of `word-prefix-anchoring`, not a special-cased boundary.
- **Redundant evidence.** Text that satisfies both the word-prefix and the
  phrase evidence for the same facet (e.g. `"coding, code generation"` for
  `coding`) MUST still yield that facet exactly once — the result is a set
  with no duplicate entries.
- **Capability and text both point to the same facet.** A model whose
  capabilities report `tools` and whose text also matches an `agents`
  keyword MUST still show `agents` exactly once: because capability-implied
  evidence for a facet is checked first and short-circuits, the word/phrase
  checks for that facet are never reached, so this cannot produce a
  duplicate or a conflict.
- **Non-English or transliterated evidence.** The word-prefix and phrase
  lists are fixed English-token lists (see Localization); a description
  written only in another language MUST produce an empty set for facets
  whose only matching keywords are English, exactly as if the model had no
  description at all — this is a fact about the fixed evidence lists, not a
  crash or undefined behavior.
- **Concurrent access.** Facet derivation and every function in this
  component are pure and hold no shared mutable state, so concurrent calls
  from multiple threads or tasks on the same or different inputs MUST
  behave identically to sequential calls — this is applicable (facets are
  read from UI code and could be read from background contexts) and is safe
  by construction, not merely untested.
- **Error states (dependency failure).** Not applicable: facet derivation
  makes no network call, file-system call, or database call of any kind —
  it operates only on the text/capability arguments and the already-in-memory
  resolved model passed to it, so there is no dependency that can be
  "unavailable" or "return an error" for this component to handle.
- **Offline or disconnected state.** Not applicable, for the same reason:
  this component performs no network I/O. Whether the resolved model it is
  given was itself fetched online or offline is a concern of its caller,
  not of facet derivation.

