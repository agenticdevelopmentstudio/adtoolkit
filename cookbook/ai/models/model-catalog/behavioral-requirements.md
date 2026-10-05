
- **model-identity**: A model entry MUST be uniquely identified by its
  canonical `id`; its `aliases` list MUST list every additional spelling a
  gateway uses for that same model (e.g. `meta-llama/Llama-3.3-70B-Instruct`,
  `@cf/meta/llama-3.3-70b-instruct-fp8-fast`).
- **model-decoding-defaults**: Decoding a model entry MUST default `aliases`
  and `capabilities` to empty lists and `description` to absent when those
  keys are missing from the input payload, rather than failing to decode the
  entry.
- **offering-is-per-gateway-spelling**: An offering record MUST be looked up
  under the exact model-name spelling that one gateway (`templateID`) uses;
  the same model's terms at a different gateway, or under its canonical id,
  MUST NOT be returned.
- **offering-fields-independently-optional**: Each field of an offering
  record (`contextWindow`, `maxOutput`, `inputCostPerM`, `outputCostPerM`)
  MUST be independently representable as absent rather than defaulted to
  zero, because "unknown" and "zero" are different facts about a gateway's
  terms.
- **lookup-resolution-order**: Looking up a model by name MUST resolve it by
  exact-case match against the name index first, THEN by lowercased match
  against the same index, THEN by canonicalizing the name and matching the
  canonical-id index; the lookup MUST return no match when none of the three
  succeed.
- **canonicalization-strips-namespace**: Computing a model's canonical id
  MUST trim leading and trailing whitespace/newlines, lowercase the result,
  and drop any path segment up to and including the last `/`.
- **canonicalization-strips-free-suffix**: Computing a canonical id MUST
  strip a trailing `:free` suffix (an OpenRouter price tier, not a different
  model).
- **canonicalization-strips-quantization-suffix**: Computing a canonical id
  MUST strip at most one trailing suffix from the fixed set `-fp8-fast`,
  `-fp8`, `-fp4`, `-bf16`, `-awq`, `-int8`, `-int4`, testing them in that
  order so `-fp8-fast` matches before the shorter `-fp8` can.
- **canonicalization-preserves-other-suffixes**: Computing a canonical id
  MUST NOT strip a suffix outside the quantization set — `-turbo`,
  `-latest`, `-fast`, `-thinking` MUST survive unchanged, because they name a
  genuinely different model or alias, not a precision variant.
- **resolve-merges-three-sources**: Resolving a model for a template MUST
  merge, for one (model name, template) pair, the shared model facts (from a
  model-name lookup), the offering for that template's gateway under the
  given spelling (from an offering lookup), and the template's curated model
  detail (from an exact-id match against the template's curated entries)
  into one resolved model.
- **curated-description-wins**: Resolving a model for a template MUST use
  the curated description when it is present and non-empty, and MUST fall
  back to the shared model's description when the curated value is absent
  or an empty string.
- **curated-tools-wins**: Resolving a model for a template MUST use the
  curated tools value when present; when absent, it MUST derive the tools
  flag from whether the shared `capabilities` list contains `"tools"`,
  yielding unknown, not false, when `capabilities` is empty.
- **terms-never-curated**: Resolving a model for a template MUST take
  `contextWindow`, `maxOutput`, `inputCostPerM`, and `outputCostPerM` only
  from the resolved offering; the template's curated model detail MUST NOT
  influence any of these four fields.
- **unknown-model-resolves-empty**: Resolving a model for a template MUST
  return a resolved model (with `id` set to the requested name and marked
  empty) for a name with no matching model entry and no matching offering,
  rather than returning no result or failing.
- **shared-catalog-never-fails-to-exist**: The shared catalog instance MUST
  always yield a usable catalog: an empty catalog (`schemaVersion: 0`, no
  models, no offerings) whenever the bundled resource is missing, unreadable,
  or fails to decode.
- **load-is-total**: Loading the catalog MUST return no result — never fail
  with an error — when the given resource location has no
  `model-catalog.json` resource, when the resource's data cannot be read, or
  when the JSON fails to decode as a catalog.
- **index-built-at-init**: Constructing a catalog MUST build the name index
  and canonical-id index synchronously from the model list during
  construction, so a model-name lookup and an offering lookup are direct
  index lookups and never re-scan the model list.
- **alias-collision-last-writer-wins**: When two model entries in the model
  list share the same alias or the same `id` spelling as another entry's
  alias, the name index MUST hold whichever model appears later in the
  model list for that spelling, because index population iterates the model
  list once, in order, and later assignments overwrite earlier ones for the
  same key.
- **codable-round-trip-excludes-indexes**: Serializing and deserializing a
  catalog MUST round-trip only `schemaVersion`, `generatedAt`, `models`, and
  `offerings`; the internal name/canonical-id indexes MUST NOT appear on the
  wire and MUST be rebuilt from the model list on every deserialization.
- **value-type-is-freely-shared**: A model entry, an offering record, a
  resolved model, and the catalog itself MUST be immutable value types with
  no mutable state after construction, so one loaded catalog instance MAY be
  read concurrently from multiple threads or tasks without additional
  synchronization.
- **schema-version-not-gated**: The catalog's `schemaVersion` MUST be
  decoded and stored but MUST NOT gate loading: nothing reads or
  range-checks it, so any decodable payload loads regardless of its
  `schemaVersion`, unlike the sibling plugin-descriptor concept's own schema
  version, which is checked against a supported range and logged and skipped
  when out of range. The catalog is a resource the framework ships itself,
  generated by its own catalog-generation tooling, so a port that adds a
  range check is extending the contract, not restoring it.

