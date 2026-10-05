
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| MUF-001 | word-tokenization, word-prefix-anchoring | Derive facets from the text "A model for coding, debugging and creative writing" | Result contains `coding` and `writing` |
| MUF-002 | capability-implied-facets | Same text | Result does not contain `conversation` (no chat/assistant/dialog wording, no `tools`/`reasoning`/`vision` capability) |
| MUF-003 | word-prefix-anchoring | Derive facets from "encoded tokens are decoded" | Result does not contain `coding` — `"cod"` occurs mid-word, not at a word start |
| MUF-004 | word-prefix-anchoring | Derive facets from "codes and coding" | Result contains `coding` |
| MUF-005 | phrase-matching-on-raw-text | Derive facets from "supports function calling" | Result contains `agents` |
| MUF-006 | phrase-matching-on-raw-text | Derive facets from "a long-context model" | Result contains `research` |
| MUF-007 | phrase-matching-on-raw-text | Derive facets from "step-by-step" | Result contains `problemSolving` |
| MUF-008 | phrase-matching-on-raw-text | Derive facets from "cost-effective for high volume" | Result contains `economy` |
| MUF-009 | capability-implied-facets, capability-evidence-checked-first | Derive facets from empty text with capabilities `["tools", "vision", "reasoning"]` | Result equals exactly `{agents, vision, problemSolving}`, with no text evidence needed |
| MUF-010 | resolved-model-evidence-sources, model-id-excluded-from-evidence | Derive facets for a resolved model with `id: "mystery-7b"`, `description: "Great at coding."`, `goodFor: "translation"` | Result is a superset of `{coding, translation}` |
| MUF-011 | model-id-excluded-from-evidence, empty-evidence-yields-empty-set | Derive facets for a resolved model with `id: "claude-opus-5-fast"` (no other evidence), and for one with `id: "qwen3-coder"` (no other evidence) | Both results are empty sets — the model id alone (`-fast`, `-coder`) is never evidence |
| MUF-012 | resolved-model-evidence-sources | Derive facets for a resolved model with `id: "mystery"` and extra text "excels at math and logic puzzles" | Result contains `problemSolving` |
| MUF-013 | per-facet-evidence-lists-are-fixed | Derive facets from "A large language model from Acme." | Result does not contain `translation` — the word "language" alone is not translation evidence (this boilerplate opener previously caused a false positive) |
| MUF-014 | per-facet-evidence-lists-are-fixed | Derive facets from "Translates between 30 languages" and from "Strong on rare language pairs" | Both results contain `translation` |
| MUF-015 | filter-empty-selection-passes-all | Match facets `{coding}` against selection `{}`, and facets `{}` against selection `{}` | Both true |
| MUF-016 | filter-any-of-semantics | Match facets `{coding}` against selection `{coding, writing}`; facets `{writing}` against `{coding, writing}`; facets `{vision}` against `{coding, writing}` | true, true, false |
| MUF-017 | filter-unknown-model-passes | Match facets `{}` against selection `{coding}` | true |
| MUF-018 | facet-title, facet-detail | Read `title` and `detail` for every facet | Every title and detail is a non-empty string |
| MUF-019 | facet-cases, codable-round-trip | Count all facets; look up the facet whose identifier is `"problemSolving"` | Count is `10`, and the looked-up facet equals `problemSolving` |
| MUF-020 | value-type-concurrency-safety | Derive facets from many concurrent tasks with different inputs | Every task returns the result for its own input with no crash, data race, or need for a lock |

