
- **capability-cases**: This capability type MUST expose exactly four
  cases — `tools`, `reasoning`, `vision`, `conversation` — each comparable
  for equality, safe to pass across concurrent boundaries, encodable and
  decodable, and enumerable as a complete set, with each case's raw
  string form equal to its case name.
- **title-labels**: The title MUST return `"Tools"` for `tools`,
  `"Reasoning"` for `reasoning`, `"Vision"` for `vision`, and `"Chat"` for
  `conversation` — note `conversation`'s label is `"Chat"`, not
  `"Conversation"`.
- **detail-tooltips**: The detail text MUST return `"Calls tools /
  functions you supply"` for `tools`, `"Thinks step by step before
  answering"` for `reasoning`, `"Accepts images as input"` for `vision`,
  and `"Built for chat, assistants and personas"` for `conversation`.
- **reported-spelling-vocabulary**: For `tools`, `reasoning`, and
  `vision`, the reports check MUST treat each case's own fixed list of
  spellings as reporting that capability — `tools`: `tools`, `tool_use`,
  `tool-use`, `function_calling`, `functioncalling`, `function-calling`,
  `functions`; `reasoning`: `reasoning`, `thinking`, `extended_thinking`,
  `extended-thinking`; `vision`: `vision`, `image`, `images`,
  `image_input`, `multimodal`.
- **reports-case-insensitive-match**: The reports check MUST match a
  capabilities entry against the case's spelling list case-insensitively
  (the entry is lowercased before comparison) and MUST return `true` as
  soon as one entry matches any spelling in the list.
- **reports-false-without-match**: The reports check MUST return `false`
  when no entry of the capabilities list matches, case-insensitively, any
  spelling in the capability's list, including when the list is empty.
- **conversation-never-self-reported**: `conversation`'s spelling list
  MUST be empty, so the reports check for `conversation` MUST return
  `false` for any capabilities list, including one containing `"chat"` or
  `"conversation"`.
- **reports-resolved-model-overload**: The reports check taking a resolved
  model directly MUST return the same result as the reports check called
  with that model's capabilities list.
- **has-short-circuits-on-report**: The has check MUST return `true`
  immediately whenever the reports check for that capability is `true`,
  without evaluating any per-case fallback.
- **has-tools-fallback-to-curated-flag**: When `tools` is not reported,
  the has check MUST return whether the resolved model's tools flag
  equals `true` — an absent or `false` tools value both yield `false`.
- **has-conversation-fallback-to-facets**: When `conversation` is not
  reported (always true, per `conversation-never-self-reported`), the has
  check MUST return whether the model's computed use facets, given the
  resolved model and any extra text, contain `conversation`.
- **has-reasoning-vision-never-inferred**: When `reasoning` or `vision` is
  not reported, the has check MUST return `false` unconditionally — it
  MUST NOT consult the model's description, its "good for" text, or the
  extra text for either of these two cases.
- **capabilities-of-order**: Computing the capabilities of a model MUST
  return the subsequence of all cases (declaration order: `tools`,
  `reasoning`, `vision`, `conversation`) for which the has check is
  `true`, preserving that order and omitting every case for which it is
  `false`.
- **pure-and-stateless**: This type MUST hold no stored instance state
  beyond its raw value and MUST perform no I/O; every operation on it
  MUST be a pure function of its arguments, so repeated calls with the
  same arguments MUST return the same result.

