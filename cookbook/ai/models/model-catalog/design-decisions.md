
- **Decision**: Split shared, per-model facts (`Model`: description,
  capabilities) from per-offering, per-gateway terms (`Offering`: context
  window, output limit, prices), keyed by `templateId` and the gateway's own
  spelling of the model.
  **Rationale**: The same model (e.g. `gpt-oss-120b`) is served by many
  gateways; describing it inside every provider's descriptor would copy one
  blurb dozens of times and let the copies drift, while a model's context
  window and token prices genuinely differ per gateway (one number would be
  wrong nearly everywhere) — both facts are stated directly in the source's
  top-of-file documentation comment.
  **Approved**: pending
- **Decision**: `AIModelCatalog.shared` never fails to exist — a missing,
  unreadable, or malformed `model-catalog.json` yields an empty catalog
  rather than a crash or a thrown error surfacing to the caller.
  **Rationale**: per the source comment on `shared`, "a stale or absent
  catalog costs descriptions, and must never take the provider UI down with
  it" — losing model descriptions is an acceptable degradation; losing the
  entire provider picker is not.
  **Approved**: pending
- **Decision**: Curated `ModelDetail` overrides only the descriptive fields
  (`description`, `tools`, `goodFor`) in `resolve(...)`, never the numeric
  `Offering` terms.
  **Rationale**: per the source comment on `resolve`, curated fields are
  "hand-written for the few flagship models where the generated blurb isn't
  good enough, and a regeneration must never silently overwrite that
  judgement" — but a gateway's context window and prices are facts the
  gateway itself reports, which curated prose has no authority to change.
  **Approved**: pending
- **Decision**: `canonicalID(_:)` strips only a fixed, explicit set of
  quantization/precision suffixes (checked longest-first), and leaves every
  other trailing token — `-turbo`, `-latest`, `-fast`, `-thinking` — alone.
  **Rationale**: `generate_model_catalog.py`'s sibling `canonical_model_id`
  (which this Swift function must mirror per its own doc comment) states
  these suffixes are "the same weights served at lower precision" and safe to
  fold onto the base model, while `-turbo`/`-fast`/`-latest`/`-thinking`
  "name genuinely different models or aliases" and must never be folded.
  **Approved**: pending
- **Decision**: `AIModelCatalog.schemaVersion` is carried on the wire and
  stored, but — unlike `AIPluginDescriptor.schemaVersion` — is never gated
  against a known-compatible range before the catalog is used.
  **Rationale**: no comment in `AIModelCatalog.swift`,
  `generate_model_catalog.py`, or the shipped catalog explains this
  asymmetry; the recipe records the behavior as it is
  (`schema-version-not-gated`): the framework ships and regenerates its own
  catalog, so there is no foreign payload to guard against today.
  **Approved**: pending

