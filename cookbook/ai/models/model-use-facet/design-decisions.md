
- **Decision**: Facets are derived on demand from text and capabilities
  (`facets(text:capabilities:)`/`facets(for:extraText:)`) rather than stored
  as data on the model or baked into `model-catalog.json`.
  **Rationale**: per the source's top-of-file comment, the evidence text a
  model carries "arrives from three places at three different times: the
  shared catalog, a template's curated `modelDetails`, and, for a local
  server, a blurb fetched from ollama.com for a model no catalog has ever
  heard of" — baking the answer into the catalog file "would serve only the
  first."
  **Approved**: pending
- **Decision**: Keyword matching is treated explicitly as a heuristic: a
  facet present means *some* evidence was found, never that its absence
  means the model is bad at that job, and a model with no evidence at all
  (`facets.isEmpty`) always passes `matches(...)` regardless of `selected`.
  **Rationale**: per the source's top-of-file comment and the `matches` doc
  comment, "a model we know *nothing* about always passes... hiding a model
  because its gateway shipped no description would quietly remove the very
  model the user came to select — including, on a local server, every model
  at once."
  **Approved**: pending
- **Decision**: A model's `id` (its name) is deliberately excluded from
  evidence, even though it is often the most on-the-nose string available
  (e.g. `qwen3-coder`).
  **Rationale**: per the `facets(for:extraText:)` doc comment, "names are
  marketing, not description: `-instruct` and `-chat` are a training-recipe
  suffix on most of the catalog rather than a claim about conversation, and
  `claude-opus-5-fast` would land the flagship model under 'Economy'."
  **Approved**: pending
- **Decision**: `matches(facets:selected:)` uses any-of (non-disjoint) rather
  than all-of (subset) semantics when multiple facets are selected.
  **Rationale**: per the `matches` doc comment, "'good for coding *or*
  writing' is how a check-several-boxes filter reads, and requiring all of
  them empties the list on the second box."
  **Approved**: pending
- **Decision**: `.translation`'s word-prefix list does not include the bare
  word `"language"`, even though it is common in translation-relevant prose.
  **Rationale**: inferred from `ModelUseFacetTests.languageIsNotTranslation`'s
  comment — `"large language model"` is "the boilerplate opener of half the
  catalog's blurbs" and previously caused every model's description to
  falsely register as translation evidence; the fixed prefix/phrase lists in
  `ModelUseFacet.swift` (`"translat"`, `"multiling"`, `"localization"`,
  `"language pairs"`, `"cross-language"`) are the result of removing that
  false-positive term, not an oversight.
  **Approved**: pending

