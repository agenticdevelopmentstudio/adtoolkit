
- **facet-cases**: The use-facet vocabulary MUST define exactly these ten
  values, in this order: `coding`, `conversation`, `problemSolving`,
  `research`, `writing`, `vision`, `agents`, `translation`, `speech`,
  `economy`. Each value's own identifier string MUST equal its case name
  verbatim (no custom identifier strings are declared), e.g. the identifier
  for `problemSolving` is `"problemSolving"`.
- **facet-title**: `title` MUST return the exact non-empty display string
  listed for each facet — `"Coding"`, `"Conversation"`, `"Problem solving"`,
  `"Research"`, `"Writing"`, `"Vision"`, `"Agents & tools"`, `"Translation"`,
  `"Speech & audio"`, `"Fast & low cost"` — for use as a menu or checkbox
  label.
- **facet-detail**: `detail` MUST return the exact non-empty tooltip string
  listed for each facet (e.g. `coding` → `"Writing, reviewing and debugging
  code"`, `economy` → `"Fast, cheap, high-volume work"`) for use as a menu
  item's tooltip.
- **capability-implied-facets**: Deriving facets from text and capabilities
  MUST insert `agents` when the reported capabilities include `tools`,
  `vision` when they include `vision`, and `problemSolving` when they
  include `reasoning` — regardless of what the text says — because the
  capability-to-facet mapping covers only those three facets. Any other facet MUST NOT be implied by a reported capability.
- **capability-evidence-checked-first**: For each facet, deriving facets
  from text and capabilities MUST check capability-implied evidence before
  word-prefix evidence, and word-prefix evidence before phrase evidence,
  short-circuiting on the first match found for that facet.
- **capability-string-matching-is-delegated**: Whether a capability string
  is "reported" MUST be decided by a shared capability-matching check, which
  matches case-insensitively against every known spelling for that
  capability (e.g. `tool_use`, `function_calling`, `functions` all count as
  `tools`) — facet derivation itself performs no string comparison against
  capability values.
- **word-tokenization**: Deriving facets from text and capabilities MUST
  lowercase the text and split it into words on every run of characters
  that is neither a Unicode letter nor a Unicode number, discarding the
  separators.
- **word-prefix-anchoring**: A facet's word-prefix evidence MUST match only
  when a whole tokenized word has one of that facet's prefixes as its
  starting substring; a prefix occurring inside a word but not at its start
  (e.g. `"cod"` inside `"encoded"`) MUST NOT count as evidence.
- **phrase-matching-on-raw-text**: A facet's phrase evidence MUST be tested
  as a substring of the full lowercased text (not of the tokenized word
  list), so phrases that span whitespace or a hyphen (`"long-context"`,
  `"step-by-step"`, `"function calling"`) are matched even though
  tokenization would otherwise split them into separate words.
- **per-facet-evidence-lists-are-fixed**: Each facet's word-prefix list and
  phrase list MUST be the fixed literal lists given for that case (e.g.
  `economy`'s prefixes `["fast", "efficient", "lightweight", "cheap",
  "inexpensive"]`, phrases `["low cost", "low-cost", "high volume",
  "high-volume", "cost-effective", "cost effective", "high throughput",
  "high-throughput"]`); `conversation` MUST have an empty phrase list.
- **resolved-model-evidence-sources**: Deriving facets for a resolved model
  MUST derive its text input by joining, in order, the model's
  `description`, its `goodFor` value, and an optional extra text — dropping
  any of the three that is absent — with a single space separator, and MUST
  pass the model's `capabilities` through unchanged as the capabilities
  input.
- **model-id-excluded-from-evidence**: Deriving facets for a resolved model
  MUST NOT use the model's `id` (its name) as evidence for any facet — only
  `description`, `goodFor`, the extra text, and `capabilities` MUST be
  considered.
- **empty-evidence-yields-empty-set**: Deriving facets from text and
  capabilities, called with an empty string and empty (or default)
  capabilities, MUST return an empty set of facets; no facet MUST ever be
  present without at least one of capability, word-prefix, or phrase
  evidence for it.
- **facets-are-a-set**: Both facet-derivation entry points MUST return a
  set of facets — a model MUST be able to carry more than one facet
  simultaneously, with no defined ordering and no duplicate entries for the
  same facet.
- **filter-empty-selection-passes-all**: Testing whether a model's facets
  match a filter selection MUST return true for every facets value when the
  selection is empty — an empty filter selection excludes nothing.
- **filter-unknown-model-passes**: Testing whether a model's facets match a
  filter selection MUST return true whenever the model's facets are empty,
  regardless of the selection, because no evidence is treated as "unknown,"
  never as "fails every use."
- **filter-any-of-semantics**: When both the model's facets and the
  selection are non-empty, the match check MUST return true if and only if
  the two sets are not disjoint (at least one facet in common) — selecting
  several uses MUST behave as "any of these," never "all of these."
- **value-type-concurrency-safety**: A use facet MUST be an immutable
  value with no stored state beyond its own identifier, and its `title`,
  `detail`, word-prefix list, phrase list, and capability mapping MUST be
  pure computed properties with no shared mutable state; both
  facet-derivation functions and the match check MUST be pure, with no
  side effects, so any number of callers on any thread MAY call them
  concurrently on the same or different inputs without synchronization.
- **codable-round-trip**: A use facet MUST serialize to and deserialize
  from its own identifier string, so a set of facets round-trips through
  JSON as an array of the raw case-name strings.
- **exhaustive-derivation-switches**: The `title`, `detail`, word-prefix,
  and phrase derivations MUST cover every facet with no fallback branch, so
  adding a facet without extending all four is a build-time error; only the
  capability mapping MUST use a fallback (no mapping) for the seven facets
  it does not map to a capability.

