
- **provider-settings-reader-shape**: The settings-reader function type
  MUST be safe to call from any concurrency domain and MUST have the shape:
  given a key (text), return an optional text value.
- **provider-settings-reader-absent-key**: A settings-reader function MUST
  return none when the given key is absent from whatever store the
  function wraps, per the type's own documented contract ("Returns nil
  when a key is absent").
- **settings-store-opacity**: The resolver MUST NOT access a settings
  store directly; every operation MUST obtain data only by invoking the
  settings function the caller supplies, per the documented contract ("the
  resolver and its caller never see the store itself").
- **configurations-empty-when-absent**: The configurations lookup MUST
  return an empty list when the settings function returns none for the
  configurations key.
- **configurations-empty-when-blank**: The configurations lookup MUST
  return an empty list when the settings function returns an empty string
  for the configurations key.
- **configurations-empty-when-malformed**: The configurations lookup MUST
  return an empty list, without raising an error, when the stored value at
  the configurations key is present and non-empty but is not valid JSON or
  does not decode as a list of provider configurations.
- **configurations-array-poisoning**: The configurations lookup MUST
  discard the entire decoded list — not just the offending element — when
  even one element of an otherwise well-formed JSON array fails to decode
  as a provider configuration; the decoder's array decoding fails
  atomically, and the failure-swallowing path turns that single-element
  failure into the same empty-list result as a fully malformed document.
- **configurations-decode-success**: The configurations lookup MUST decode
  the stored JSON string at the configurations key into a list of provider
  configurations and MUST return it in the same element order when
  decoding succeeds.
- **decode-failure-diagnostics**: When the settings function returns a
  non-empty string that fails to decode as a list of provider
  configurations, the configurations lookup MUST swallow the decode error
  and return an empty list, emitting no log call, error return, or other
  diagnostic signal; a corrupt-but-present registry is therefore
  indistinguishable from "zero configurations registered." (See the Design
  Decision on decode-failure signalling.)
- **selected-configuration-absent**: The selected-configuration lookup MUST
  return none when the settings function returns none or an empty string
  for the selected-configuration-id key.
- **selected-configuration-malformed-id**: The selected-configuration
  lookup MUST return none when the stored value at the
  selected-configuration-id key is not parseable as a configuration
  identifier.
- **selected-configuration-lookup**: The selected-configuration lookup
  MUST return the first element of the configurations list whose
  identifier equals the parsed identifier, and MUST return none when no
  element matches.
- **selected-configuration-duplicate-id-order**: When more than one
  element of the decoded registry shares the same identifier, the
  selected-configuration lookup MUST return the first such element in list
  order; the resolver enforces no uniqueness invariant of its own over the
  registry.
- **selected-configuration-fallback-signal**: A caller SHOULD treat a none
  result from the selected-configuration lookup as "no configuration
  selected — use the zero-config path," not as an error condition,
  matching how the daemon's chat-completion operation falls through to its
  command-line path when the selected-configuration lookup returns none.
- **model-empty-when-unset**: The model lookup MUST return an empty string
  when the settings function returns none for that configuration's model
  key.
- **model-verbatim-value**: The model lookup MUST return the exact string
  stored at that configuration's model key when present, with no trimming,
  case-folding, or validation applied.
- **model-lookup-independent-of-registry**: The model lookup MUST look up
  the stored model by the given identifier alone; it MUST NOT check
  whether that identifier is present in the configurations list or matches
  the currently selected configuration.
- **stateless-namespace**: Every operation in the resolver MUST be a pure
  function of its arguments and of what the supplied settings function
  returns at the moment of the call; the resolver MUST hold no stored
  property of its own.
- **no-instantiation**: The resolver MUST NOT be instantiated; it is a
  namespace of operations with no case or instance, so every member MUST
  be accessed as a type-level member.
- **no-persistence**: The resolver MUST NOT write to the settings store, a
  file, or any other persistent medium; the source contains no such call.
- **no-side-effects**: The resolver MUST NOT perform network access,
  subprocess execution, or notification posting; the source contains no
  such call.
- **any-thread-invocation**: The resolver's operations MUST be callable
  from any concurrency domain with no suspension and no synchronization;
  the type declares no confinement to a single execution context and holds
  no shared mutable state.
- **no-caching**: The resolver MUST NOT cache a prior call's result; every
  call MUST re-invoke the settings function and, where applicable, re-run
  the decoder, so a change to the underlying store between two calls MUST
  be visible on the next call.

