
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| MC-001 | reported-spelling-vocabulary, reports-case-insensitive-match | Check whether `tools` is reported for capabilities lists containing each of `"tools"`, `"Tools"`, `"tool_use"`, `"function_calling"`, `"functionCalling"`, one spelling at a time. | Returns `true` for every spelling. |
| MC-002 | reported-spelling-vocabulary | Check whether `reasoning` is reported for a capabilities list containing `"thinking"`. | `true`. |
| MC-003 | reported-spelling-vocabulary | Check whether `vision` is reported for a capabilities list containing `"multimodal"`. | `true`. |
| MC-004 | reports-false-without-match | Check whether `vision` is reported for a capabilities list containing `"tools"` and `"reasoning"`. | `false` — an unrelated reported capability is not evidence. |
| MC-005 | conversation-never-self-reported | Check whether `conversation` is reported for a capabilities list containing `"chat"`. | `false`. |
| MC-006 | has-tools-fallback-to-curated-flag, capabilities-of-order | For a resolved model with id `"m"`, capabilities `["vision"]`, and tools `true`: check whether `tools` is present, and compute the model's capabilities. | The `tools` check is `true`; the computed capabilities are `[tools, vision]`. |
| MC-007 | has-conversation-fallback-to-facets | Check whether `conversation` is present for a resolved model with id `"m"` and no description, "good for" text, or extra text. | `false`. |
| MC-008 | has-conversation-fallback-to-facets, has-short-circuits-on-report | Check whether `conversation` is present for a resolved model with id `"m"` and extra text `"A chat assistant model"`. | `true`. |
| MC-009 | capabilities-of-order | Compute the capabilities of a resolved model with id `"m"` and extra text `"A chat assistant model"`. | `[conversation]` (no other case present). |
| MC-010 | has-conversation-fallback-to-facets | Check whether `conversation` is present for a resolved model with id `"m"` and description `"Built for conversation"`. | `true` — derived from the description alone, no extra text needed. |
| MC-011 | has-reasoning-vision-never-inferred | For a resolved model with id `"m"` and description `"Exceptional reasoning over images and charts"`, check whether `reasoning` is present and whether `vision` is present. | Both `false` — prose is not a gateway assertion. |
| MC-012 | title-labels, detail-tooltips | Read the title and detail text for `conversation`. | `"Chat"`; `"Built for chat, assistants and personas"`. |
| MC-013 | capability-cases | Read the full set of cases, and look up the case whose raw value is `"tools"`. | The full set is `[tools, reasoning, vision, conversation]`; the case looked up by raw value `"tools"` is `tools`. |
| MC-014 | reports-resolved-model-overload | Check whether `vision` is reported for a resolved model with id `"m"` and capabilities `["multimodal"]`, using the resolved-model overload directly. | `true`, identical to checking whether `vision` is reported for a capabilities list containing `"multimodal"`. |
| MC-015 | pure-and-stateless | Check whether `tools` is reported for a capabilities list containing `"tools"`, called twice in sequence, and again from two concurrent tasks. | Every call returns `true` with no observable difference and no synchronization required. |

