
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| AMC-001 | model-identity | Look up a model by the names `"gpt-oss-120b"`, `"openai/gpt-oss-120b"`, `"accounts/fireworks/models/gpt-oss-120b"`, `"OpenAI/GPT-OSS-120B"` | All four resolve to the model entry whose `id == "gpt-oss-120b"` |
| AMC-002 | model-decoding-defaults | Decode `{"schemaVersion":1,"models":[{"id":"m"}]}` | Looking up `"m"` returns a model entry with `aliases == []`, `description` absent, `capabilities == []`; the catalog's offerings are empty |
| AMC-003 | offering-is-per-gateway-spelling | Look up the offering for gateway `"groq"` and model name `"openai/gpt-oss-120b"`, versus the offering for gateway `"groq"` and model name `"accounts/fireworks/models/gpt-oss-120b"` | First returns `contextWindow == 131_072`; second returns no match (right model, wrong gateway's spelling) |
| AMC-004 | offering-fields-independently-optional | A sample Fireworks offering carries only `contextWindow: 1_000_000` | That offering's `maxOutput`, `inputCostPerM`, `outputCostPerM` are all absent, not `0` |
| AMC-005 | lookup-resolution-order | Look up `"OpenAI/GPT-OSS-120B"` (case fallback) and `"@cf/openai/gpt-oss-120b-fp8"` (no gateway spells it this way; canonical fallback) | Both resolve to `id == "gpt-oss-120b"` |
| AMC-006 | canonicalization-strips-namespace | Compute the canonical id of `"meta-llama/Llama-3.3-70B-Instruct"` | `"llama-3.3-70b-instruct"` |
| AMC-007 | canonicalization-strips-free-suffix | Compute the canonical id of `"deepseek/deepseek-r1:free"` | `"deepseek-r1"` |
| AMC-008 | canonicalization-strips-quantization-suffix | Compute the canonical id of `"@cf/meta/llama-3.3-70b-instruct-fp8-fast"` | `"llama-3.3-70b-instruct"` (matches the longer `-fp8-fast`, not the shorter `-fp8`) |
| AMC-009 | canonicalization-preserves-other-suffixes | Compute the canonical id of `"gpt-4-turbo"` and of `"grok-2-latest"` | Both unchanged |
| AMC-010 | resolve-merges-three-sources | Resolve `"openai/gpt-oss-120b"` for the groq template | `description` from the shared model entry, `contextWindow`/`inputCostPerM` from the groq offering |
| AMC-011 | curated-description-wins | Same resolution, with the template's curated details including an entry for `"openai/gpt-oss-120b"` with description `"Hand-written."` | Resolved `description == "Hand-written."`, not the shared blurb |
| AMC-012 | curated-tools-wins | (a) curated `tools: false` over shared capabilities containing `"tools"`; (b) no curated details, shared `capabilities == []` | (a) resolved `tools == false`; (b) resolved `tools` is unknown, not false |
| AMC-013 | terms-never-curated | Curated model detail present (description/tools/goodFor only — it carries no numeric fields) | Resolved `contextWindow` still equals the groq offering's `131_072`, unaffected by curation |
| AMC-014 | unknown-model-resolves-empty | Resolve `"nonesuch-9b"` for the groq template | Resolved `id == "nonesuch-9b"`, resolved is marked empty, no failure |
| AMC-015 | shared-catalog-never-fails-to-exist, load-is-total | Load the catalog from a resource location with no bundled resource present | Load returns no result; the shared catalog instance's `schemaVersion >= 0` still holds (fallback empty catalog, never a crash) |
| AMC-016 | load-is-total (positive path) | Load the catalog from the framework's real bundled resource | Load succeeds; `schemaVersion == 1`, model count `> 100`, offerings non-empty, every model's `id` non-empty |
| AMC-017 | index-built-at-init | Construct a catalog directly from `schemaVersion: 1, generatedAt: absent, models: [a model entry with id "gpt-oss-120b" and its aliases], offerings: [:]` | A model-name lookup resolves every alias immediately with no separate build step |
| AMC-018 | alias-collision-last-writer-wins | A model list containing a model with `id: "a"` and alias `"shared"`, followed by a model with `id: "b"` and alias `"shared"` | Looking up `"shared"` resolves to `id == "b"` (the later list entry wins) |
| AMC-019 | codable-round-trip-excludes-indexes | Serialize a sample catalog, then deserialize it | The deserialized catalog's lookups behave identically to the original; the serialized form has only `schemaVersion`/`generatedAt`/`models`/`offerings` keys |
| AMC-020 | value-type-is-freely-shared | The shared catalog instance read concurrently from multiple threads or tasks | Every reader observes the same, consistent lookups, with no additional synchronization required, because the catalog and its records are immutable value types |
| AMC-021 | schema-version-not-gated | A hypothetical catalog payload with `"schemaVersion": 99` and an otherwise-valid shape | Decodes and loads successfully with no warning, unlike an out-of-range plugin-descriptor schema version, which is logged and skipped |

