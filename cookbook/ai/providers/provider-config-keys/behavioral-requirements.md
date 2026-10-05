
- **field-key-format**: The field-key operation MUST return the string
  `aiplugin.config.<id>.field.<field>`, where `<id>` is the configuration
  identifier's canonical uppercase, hyphenated string form and `<field>` is
  the given field name, both interpolated verbatim and unescaped.
- **model-key-format**: The model-key operation MUST return the string
  `aiplugin.config.<id>.model`.
- **secret-fields-key-format**: The secret-fields-key operation MUST
  return the string `aiplugin.config.<id>.secretfields`.
- **fields-key-format**: The fields-key operation MUST return the string
  `aiplugin.config.<id>.fields`.
- **registry-keys-fixed**: The selected-configuration-id key, configurations
  key, enabled key, and legacy-cleaned key MUST each equal one fixed
  literal string — `"ai_selected_config_id"`, `"ai_configurations"`,
  `"ai_summaries_enabled"`, and `"ai_legacy_cleaned"` respectively — the
  same for every configuration and every call, never parameterized by a
  configuration identifier.
- **key-namespace-isolation**: The field-key, model-key, secret-fields-key,
  and fields-key operations MUST embed the configuration identifier as a
  distinct path segment (`aiplugin.config.<id>.…`), so calling any one of
  them with two different configuration identifiers and the same remaining
  arguments MUST produce two different key strings.
- **fields-ledger-format**: the value a caller stores under the key the
  fields-key operation returns MUST be a newline (`\n`)-separated list of
  the configuration's currently-stored non-secret field keys — the shape
  this component's own documented contract declares ("Newline-joined …
  value keys stored for the configuration"), and the shape the daemon's
  chat-completion path actually parses by splitting on `\n` after its own
  test double seeds it with the field names joined by `\n`.
- **secret-fields-ledger-format**: the value a caller stores under the key
  the secret-fields-key operation returns MUST be a newline (`\n`)-separated
  list of the descriptor field keys whose secrets are currently stored for
  that configuration — the shape this component's own documented contract
  declares ("Newline-joined descriptor field keys whose *secrets* are
  currently stored for the configuration").
- **pure-computation**: every operation MUST be a deterministic function of
  its arguments alone: calling it any number of times with the same
  arguments MUST return the same string every time.
- **no-persistence**: this component MUST NOT read from or write to a
  settings store, a secure credential store, or any file itself; it holds
  no stored state and calls no persistence operation of its own — it only
  formats and returns key strings for callers to use against their own
  store.
- **no-side-effects**: calling any operation MUST NOT perform network
  access, file I/O, subprocess execution, or notification posting; the
  source contains no such call.
- **no-error-domain**: no operation MUST fail, and none MUST signal
  failure through an optional or empty result; every operation always
  succeeds structurally regardless of its input, because none of them
  validates its argument in a way that could reject it.
- **no-instantiation**: this component MUST NOT be instantiated; it is a
  namespace of operations with no case or instance, so every member MUST
  be accessed as a type-level member.
- **concurrency-isolation**: this component MUST be callable synchronously,
  with no suspension and no synchronization, from any concurrency domain;
  it declares no confinement to a single execution context and holds no
  shared mutable state a concurrent caller could race on.
- **single-source-of-truth-usage**: a caller that needs one of these
  storage keys SHOULD obtain it from this component rather than
  duplicating the literal string, so the app and daemon layouts cannot
  drift, per this component's own documented contract; any deviation MUST
  be documented — see Design Decisions for the one known deviation (a
  separate settings-configuration component's independent
  `"ai_summaries_enabled"` literal).
- **field-character-permissiveness**: a caller MAY pass a field name
  containing any character other than `\n` (including `.`, whitespace, or
  an empty string) to the field-key operation; this component places no
  other restriction on the character set, so a plugin author choosing a
  field-key spelling MAY use any identifier that avoids embedding a
  newline (see field-name-newline-safety, below).
- **field-name-newline-safety**: The field-key operation and the per-field
  names recorded in the fields-key/secret-fields-key ledgers MUST be
  treated as unvalidated: this component performs no check that a field
  name excludes the `\n` character, and the ledgers' shape is a
  newline-joined list of those names (see fields-ledger-format), so a field
  name containing `\n` splits into two entries when a ledger is parsed by
  splitting on `\n`. Callers MUST NOT pass a field name containing `\n`.
- **secret-fields-key-consumer**: The secret-fields-key operation returns
  the address of a newline-joined ledger of a configuration's secret field
  names, which its documented contract says exists so removal can clear
  exactly those entries; no code in this repository writes or reads that
  key. The app-side configuration store clears a removed configuration's
  secrets by iterating the caller-supplied field-descriptor list directly,
  not via this ledger.

