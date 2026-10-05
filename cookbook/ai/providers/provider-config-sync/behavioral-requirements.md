
- **enabled-flag**: The sync envelope MUST carry a required boolean field,
  `enabled`, recording whether AI summaries are enabled.
- **selected-config-id-optional**: The sync envelope MUST declare
  `selectedConfigId` as an optional identifier; per this component's own
  documented contract, "nil / absent == zero-config path" — the
  configuration used for one-shot completions when a value is present, and
  the zero-config command-line default (per the daemon's chat-completion
  path) when it is absent.
- **configs-collection**: The sync envelope MUST carry `configs`, a list
  of resolved provider configuration records, described by this component
  as "Every configured provider, fully resolved (values + secrets)."
- **full-registry-snapshot**: The sync envelope MUST represent one
  complete, self-contained snapshot of the entire provider registry —
  every currently configured provider plus the current selection — because
  the type declares no delta, patch, or removed-ids shape; this
  component's own documented contract states this is the reason it
  exists, replacing "the old flattened push" so "the daemon mirrors the
  full registry ... rather than a single plugin-keyed slot."
- **resolved-config-identity-fields**: The resolved-configuration record
  MUST carry `id`, `name`, `pluginIdentifier`, and `templateId` — the same
  four identity fields a provider configuration carries — plus `model`,
  none of which has a default value in the constructor.
- **resolved-config-value-split**: The resolved-configuration record MUST
  carry a configuration's resolved value bag split into two same-shaped
  text-to-text maps, `values` (non-secret fields) and `secrets` (secret
  fields), each keyed by the field's own key string — the same key a field
  would address via the provider-configuration-keys component's field-key
  operation.
- **empty-secret-clears-credential**: An empty string value under a key in
  the resolved-configuration record's `secrets` map MUST be interpreted,
  per this component's own documented contract, as meaning "clear this
  credential" — i.e. a present-but-empty secret is a distinct, meaningful
  signal from that key being absent from `secrets` altogether.
- **serialized-field-names**: The sync envelope and resolved-configuration
  record MUST serialize and deserialize using their default field-by-field
  encoding with no custom key mapping, so the wire's JSON keys are exactly
  the type's own field names: `enabled`, `selectedConfigId`, `configs` for
  the envelope, and `id`, `name`, `pluginIdentifier`, `templateId`,
  `model`, `values`, `secrets` for each resolved configuration.
- **selected-config-id-omits-key-when-nil**: Encoding a sync envelope
  whose `selectedConfigId` is absent MUST omit the `selectedConfigId` key
  from the JSON entirely rather than writing it as a null value, because
  the default encoding calls the presence-aware encoding path for an
  optional-typed stored field.
- **selected-config-id-decodes-missing-as-nil**: Decoding a JSON object
  that omits the `selectedConfigId` key MUST succeed and yield an absent
  `selectedConfigId`, demonstrated by decoding `{"enabled":false,"configs":[]}`
  and observing the decoded value's `selectedConfigId` is absent.
- **structural-equality**: The sync envelope and resolved-configuration
  record MUST support equality comparison, comparing two instances equal
  if and only if every stored field is equal — a structural, field-by-field
  comparison — demonstrated by asserting a decoded value equals the
  original it was encoded from.
- **concurrent-share-safety**: The sync envelope and resolved-configuration
  record MUST be safe to share across concurrency domains; every stored
  field (boolean, optional identifier, text, text-to-text maps, and lists
  of these safe-to-share types) is itself safe to share, so no manual
  synchronization is required to pass a value from the app's process into
  a daemon-facing call, or across any concurrent-execution-context
  boundary.
- **concurrency-isolation**: The sync envelope and resolved-configuration
  record MUST be usable synchronously from any concurrency domain with no
  suspension; neither type declares confinement to a single execution
  context, so every constructor and field access is unconfined by
  default.
- **mutable-stored-properties**: Every stored field of the sync envelope
  (`enabled`, `selectedConfigId`, `configs`) and of the
  resolved-configuration record (`id`, `name`, `pluginIdentifier`,
  `templateId`, `model`, `values`, `secrets`) MUST be mutable, not fixed
  at construction; unlike an immutable value type, an existing local
  instance MAY have any of these fields reassigned in place after
  construction.
- **memberwise-initializers**: The sync envelope and resolved-configuration
  record MUST each expose a constructor taking every stored field as a
  required parameter with no default value, so every field MUST be
  supplied explicitly at construction (including an explicitly-absent
  `selectedConfigId` when there is no selection).
- **no-persistence**: The sync envelope and resolved-configuration record
  MUST NOT read from or write to a settings store, a secure credential
  store, or a file themselves; this component declares only stored
  fields, a constructor, and its serialization/equality behavior.
- **no-side-effects**: Constructing, encoding, decoding, or reading any
  field of either type MUST NOT perform network access, subprocess
  execution, or notification posting; the source contains no such call.
- **no-error-domain**: The constructors MUST NOT fail, and this component
  MUST NOT declare an error type; construction always succeeds
  structurally for any argument values supplied, because the source
  performs no content validation (see Edge Cases).
- **sync-application-unimplemented**: This component MUST be treated as the
  wire shape only: no function in this repository decodes an incoming
  sync-envelope payload and persists it under the provider-configuration
  key namespace, and none constructs and transmits an envelope from the
  app side; the only place an envelope is constructed in this repository is
  this component's own round-trip test. The sender and receiver are
  expected to live in the host that owns the transport.
- **configs-id-uniqueness-unenforced**: The envelope's `configs` field MUST
  be accepted as a plain list: this component performs no check that every
  entry's identifier is unique, so two entries sharing an identifier decode
  without error, and any receiver that persists them under the
  provider-configuration key namespace would let one silently overwrite the
  other.

