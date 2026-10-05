
- **schema-version-field**: A plugin descriptor MUST include a
  `schemaVersion` integer field identifying the descriptor schema the
  plugin bundle was authored against; this concept imposes no minimum or
  maximum on the value, and any integer decodes successfully.
- **current-schema-version-constant**: The descriptor concept MUST expose a
  shared constant, `currentSchemaVersion = 3`, naming the newest schema
  version the host understands; this constant is not itself an enforcement
  mechanism (see Design Decisions).
- **identity-fields-required**: A plugin descriptor MUST require
  `identifier`, `displayName`, and `version` string fields, each with no
  default value; this concept performs no format or non-empty validation on
  any of the three.
- **models-list**: A plugin descriptor MUST expose a `models` list of
  strings, the model identifiers a host renders as a popup, defaulting to
  an empty list when constructed directly.
- **default-model-optional**: A plugin descriptor MUST allow `defaultModel`
  to be absent, defaulting to absent when constructed directly.
- **resolved-default-model**: Resolving a descriptor's default model MUST
  return `defaultModel` when it is present, else the first entry of
  `models`, else the empty string.
- **fields-list**: A plugin descriptor MUST expose a `fields` list, the
  settings the host renders as a form and persists per plugin, defaulting
  to an empty list when constructed directly.
- **templates-optional**: A plugin descriptor MUST allow `templates` to be
  absent (a v2 descriptor with no explicit templates) or a present list,
  defaulting to absent when constructed directly.
- **resolved-templates-explicit**: Resolving a descriptor's templates MUST
  return `templates` unchanged when it is present and contains at least one
  element.
- **resolved-templates-implicit-synthesis**: When `templates` is absent or
  an empty list, resolving a descriptor's templates MUST return exactly one
  synthesized provider template with `id: "default"`, `displayName` equal
  to the descriptor's `displayName`, empty `defaultValues`,
  `models`/`defaultModel` copied from the descriptor, `secretRequired:
  true`, and `fields` equal to the descriptor's own `fields`.
- **fields-for-template**: Resolving the fields for a template MUST return
  the given provider template's own `fields` when present, else the
  descriptor's `fields`.
- **field-identity**: A field MUST require `key`, `label`, and `kind`
  values, and MUST allow `placeholder` to default to absent.
- **field-kind-values**: A field's `kind` MUST be exactly one of `secret`
  or `text`, whose wire identifier equals its own case name.
- **field-kind-storage-contract**: A field whose `kind` is `secret` MUST be
  understood by config-persistence consumers as a masked entry requiring
  secure (e.g. keychain) storage (API keys, tokens), and a field whose
  `kind` is `text` MUST be understood as a plain entry requiring
  non-secure storage (e.g. user defaults, base URLs); the descriptor
  concept itself performs no storage — the contract is honored by sibling
  config-store components.
- **field-is-secret**: A field's `isSecret` value MUST be true if and only
  if its `kind` is `secret`.
- **model-detail-identity**: Per-model detail MUST require an `id`, and
  MUST allow `description`, `tools`, and `goodFor` to each independently
  default to absent.
- **model-detail-lookup**: Looking up a template's per-model detail MUST
  return the first element of `modelDetails` whose `id` equals the given
  model id, or no result when `modelDetails` is absent or contains no
  matching `id`.
- **provider-template-identity**: A provider template MUST require `id`
  and `displayName`, and MUST default `defaultValues` to an empty map,
  `models` to an empty list, `defaultModel` to absent, `secretRequired` to
  true, and `fields`, `provider`, `llm`, `configType`,
  `providerDescription`, `llmDescription`, and `modelDetails` each to
  absent.
- **provider-template-resolved-default-model**: Resolving a template's
  default model MUST return `defaultModel` when present, else the first
  entry of `models`, else the empty string — the identical rule as
  resolving a descriptor's default model.
- **provider-template-resolved-provider**: Resolving a template's provider
  name MUST return `provider` when present, else `displayName`.
- **provider-template-resolved-llm**: Resolving a template's model-brand
  label MUST return `llm` when present, else the empty string.
- **provider-template-resolved-config-type**: Resolving a template's
  config type MUST return `configType` when it is present; when
  `configType` is absent, it MUST return the literal string `"API Key"` if
  `secretRequired` is `true`, and the literal string `"Local"` otherwise.
- **json-decoding-required-keys**: Because the descriptor concept declares
  no custom decoding logic, decoding from JSON MUST require every
  non-optional field's JSON key to be present at decode time — for the
  descriptor: `schemaVersion`, `identifier`, `displayName`, `version`,
  `models`, `fields`; for a field: `key`, `label`, `kind`; for a provider
  template: `id`, `displayName`, `defaultValues`, `models`,
  `secretRequired`; for per-model detail: `id`. Decoding MUST fail with a
  key-not-found error if any of these is absent, even though the
  corresponding direct-construction initializer has a default value for
  programmatic construction.
- **json-decoding-optional-keys**: Every optional field (`defaultModel`,
  `templates` on the descriptor; `placeholder` on a field; `defaultModel`,
  `fields`, `provider`, `llm`, `configType`, `providerDescription`,
  `llmDescription`, `modelDetails` on a provider template; `description`,
  `tools`, `goodFor` on per-model detail) MUST decode successfully to
  absent when its JSON key is absent or explicitly `null`.
- **codable-conformance**: A descriptor, a field, per-model detail, and a
  provider template MUST each be serializable to and deserializable from
  JSON directly, so a plugin's `descriptor.json` resource decodes without a
  custom parsing step.
- **equatable-conformance**: A descriptor, a field, per-model detail, and a
  provider template MUST each support equality comparison.
- **sendable-and-immutability**: A descriptor, a field, per-model detail,
  and a provider template MUST each be immutable value types with no
  mutable state after construction, so an instance is fully immutable and
  may cross a concurrency-domain boundary with no synchronization.
- **decoding-error-propagation**: The descriptor concept MUST NOT catch,
  transform, or swallow a decode failure; decoding MUST propagate whatever
  error the underlying JSON decoder produces to the caller, since the
  descriptor declares no custom decoding logic, no validation logic, and no
  error type of its own.

