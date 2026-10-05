
- **decodes-vscode-package-json-subset**: a manifest MUST decode as a
  subset of a VS Code `package.json`, using a standard JSON decoder with no
  custom key-decoding strategy, date-decoding strategy, or extra decode
  context.
- **top-level-identity-required**: decoding a manifest MUST fail entirely
  when `name`, `version`, or `engines.vscode` is missing or the wrong JSON
  type — each of these three is decoded as required, never treated as
  optional or leniently recovered.
- **identity-decoded-before-lenient-fields**: decoding a manifest MUST
  decode `name`, `publisher`, `version`, `displayName`, `description`,
  `engines`, `main`, and `browser` before attempting `activationEvents`,
  `extensionKind`, `capabilities`, or `contributes`, so the manifest's own
  name is always available before any field that can independently fail is
  attempted.
- **optional-descriptive-fields-decode-if-present**: `publisher`,
  `displayName`, `description`, `main`, and `browser` MUST decode leniently
  for absence — yielding an absent value when the key is absent or JSON
  `null` — but MUST fail the whole decode if the key is present with an
  incompatible JSON type.
- **engines-vscode-required**: the engines block MUST require a `vscode`
  string field; an `engines` object omitting `vscode`, or giving it a
  non-string value, MUST fail the whole manifest decode.
- **display-identifier-composition**: `displayIdentifier` MUST return
  `"<publisher>.<name>"` when `publisher` is present, and MUST return
  `name` unchanged when `publisher` is absent.
- **identifier-case-folding**: `identifier` MUST return `displayIdentifier`
  lowercased; two manifests whose `publisher`/`name` differ only in case
  MUST produce the same `identifier` while each keeps its own distinct
  `displayIdentifier`.
- **activation-events-defaults-empty**: `activationEvents` MUST default to
  an empty list, never an absent value, when the key is absent, because VS
  Code 1.74+ infers activation from `contributes` and an extension relying
  on that inference omits the key entirely.
- **activation-events-tolerant**: a present `activationEvents` value that
  is not an array of strings MUST NOT fail the manifest decode; it MUST
  resolve to an empty list and record exactly one decoding failure keyed
  `"activationEvents"`.
- **extension-kind-nil-means-absent**: `extensionKind` MUST be absent, not
  an empty list, when the key is absent or its value is unreadable — an
  empty list is reserved for a manifest that explicitly declares it runs in
  no extension host at all.
- **extension-kind-tolerant**: a present `extensionKind` value that is not
  an array of strings MUST NOT fail the manifest decode; it MUST resolve to
  absent and record exactly one decoding failure keyed `"extensionKind"`.
- **capabilities-tolerant**: a present `capabilities` value that fails to
  decode as the capabilities block MUST NOT fail the manifest decode; it
  MUST resolve to absent and record exactly one decoding failure keyed
  `"capabilities"`.
- **contributes-strict**: `contributes` MUST decode leniently only for
  absence, with no per-entry recovery of its own; a present `contributes`
  key whose shape cannot even begin to parse MUST fail and sink the entire
  manifest decode.
- **untrusted-workspaces-support-tri-form**: the untrusted-workspaces
  support value MUST decode JSON `true` as supported, JSON `false` as
  unsupported, and the JSON string `"limited"` as limited, and MUST fail
  for any other value; encoding MUST invert the same mapping exactly.
- **decoding-failures-not-encoded**: a manifest's recorded decoding
  failures, and the contributions value's recorded decoding failures, MUST
  NOT be included when either value is encoded back to JSON — they
  describe one decode attempt, not manifest content.
- **contributions-empty-static-value**: the empty contributions value MUST
  have every list empty, every dictionary empty, and no recorded decoding
  failures.
- **contributions-absent-vs-empty-equivalence**: a manifest whose
  `contributes` key is entirely absent and a contributions value whose own
  keys are all absent MUST be treated as the same statement — "this
  extension declares nothing" — which is what makes the empty contributions
  value a reusable stand-in for either case.
- **contributions-arrays-default-empty**: each of `themes`, `snippets`,
  `languages`, `commands`, `keybindings`, `configuration`, and
  `languageModelTools` MUST default to an empty list when its manifest key
  is absent.
- **contributions-dictionaries-default-empty**: each of `menus`, `views`,
  and `viewsContainers` MUST default to an empty dictionary when its
  manifest key is absent.
- **contributions-encode-lossy**: encoding the contributions value back to
  JSON MUST NOT be a faithful round-trip of the manifest that was decoded —
  it MUST omit the recorded decoding failures (per
  `decoding-failures-not-encoded`) and MUST omit every `contributes.*`
  entry that failed to decode, since the contributions value never held
  those entries to begin with.
- **lenient-array-absent-key-returns-empty**: the shared array-decoding
  helper MUST return an empty list without recording a decoding failure
  when the key is absent from the manifest.
- **lenient-array-strict-fast-path**: the shared array-decoding helper MUST
  first attempt to decode the key's value directly as an array of the
  expected element type, and return that result directly when it succeeds,
  without building any intermediate generic-JSON representation.
- **lenient-array-single-object-tolerance**: when the direct array decode
  fails, the shared array-decoding helper MUST accept a single JSON object
  in place of a one-element array — treated as a one-element array — for
  every array-shaped `contributes` key, including ones (`commands`,
  `themes`) whose own VS Code schema requires strictly an array.
- **lenient-array-non-array-non-object-failure**: when the manifest value
  for the key is neither an array nor a single JSON object, the shared
  array-decoding helper MUST return an empty list and record exactly one
  decoding failure for that key with no index and reason `"expected an
  array"`.
- **lenient-array-element-isolation**: once the array is obtained
  (directly, or via the single-object recovery path), each element MUST be
  decoded independently; an element that fails to decode as its expected
  type MUST be dropped from the result and recorded as one decoding
  failure carrying that element's index, while every other element in the
  same array MUST still decode.
- **lenient-array-strict-first-perf-rationale**: the whole-array
  direct-decode attempt MUST run before the per-element recovery path, and
  the recovery path MUST run only when the direct attempt fails — measured
  at roughly 275ms of CPU time for the recovery path against roughly 4ms of
  file I/O on a 100-synthetic-extension benchmark, so a well-formed
  manifest MUST NOT pay the per-element round-trip cost.
- **lenient-dictionary-absent-key-returns-empty**: the shared
  dictionary-decoding helper MUST return an empty dictionary without
  recording a decoding failure when the key is absent from the manifest.
- **lenient-dictionary-strict-fast-path**: the shared dictionary-decoding
  helper MUST first attempt to decode the key's value directly as a
  dictionary of string to a list of the expected element type, and return
  it directly when it succeeds.
- **lenient-dictionary-whole-value-failure**: when the manifest value for
  the key cannot decode as a generic string-keyed JSON object at all, the
  shared dictionary-decoding helper MUST return an empty dictionary and
  record exactly one decoding failure for the bare key, with no index and
  reason `"expected an object"`.
- **lenient-dictionary-location-isolation**: for each location key in the
  decoded string-keyed object, a value that is not itself a JSON array MUST
  be skipped and recorded as one decoding failure keyed
  `"<key>.<location>"` with no index, while every other location in the
  same dictionary MUST still decode.
- **lenient-dictionary-element-isolation**: within one location's array,
  each element MUST decode independently the same way the shared
  array-decoding helper does; an element that fails MUST be recorded as one
  decoding failure keyed `"<key>.<location>"` with that element's index,
  while sibling elements in the same location MUST still decode.
- **lenient-value-absent-vs-unreadable**: the shared value-decoding helper
  MUST return absent without recording a decoding failure when the key is
  absent, and MUST return absent while recording exactly one decoding
  failure when the key is present but the value's own decode fails.
- **decoding-failure-text-key-not-found**: the failure-text renderer MUST
  render a missing-key failure as `no "<key>"` using the missing key's
  name.
- **decoding-failure-text-type-mismatch-named**: the failure-text renderer
  MUST render a type-mismatch failure as `<subject> is not <name>` when a
  JSON noun is known for the expected type.
- **decoding-failure-text-type-mismatch-unnamed**: the failure-text
  renderer MUST render a type-mismatch failure for a type with no known
  JSON noun (a first-party type with its own custom decoding) as
  `<subject> is the wrong kind of value`, never interpolating the type's
  own name.
- **decoding-failure-text-value-not-found**: the failure-text renderer
  MUST render a missing-value failure as `<subject> is null`.
- **decoding-failure-text-data-corrupted**: the failure-text renderer MUST
  render a corrupted-data failure as its underlying description verbatim.
- **decoding-failure-text-non-decoding-error**: the failure-text renderer
  MUST render any failure that is not one of the four decoding-failure
  shapes above — including an unrecognized future case — as that failure's
  own localized description.
- **decoding-failure-subject-empty-path**: resolving a failure's subject
  MUST return the literal `this entry` when the failure's location path is
  empty, and MUST otherwise return the dot-joined path wrapped in curly
  quotes.
- **json-value-shape**: a generic JSON value MUST decode and encode
  exactly the six JSON value kinds — null, boolean, number, string, array,
  and object — trying each case in order on decode and failing only if
  none match.
- **theme-strict-shape**: a theme entry MUST require `label`, `uiTheme`,
  and `path` as strings, with no per-field leniency of its own — a
  malformed field MUST fail only that array element, via
  `lenient-array-element-isolation`, never the whole manifest.
- **snippet-strict-shape**: a snippet entry MUST require `language` and
  `path` as strings.
- **language-optional-fields**: a language entry MUST require `id` as a
  string and MUST treat `aliases`, `extensions`, `filenames`,
  `filenamePatterns`, `firstLine`, `mimetypes`, `configuration`, and `icon`
  as ordinary optional fields with no per-field tolerance beyond the
  standard optional-field handling. `mimetypes` MUST be carried even though
  nothing in this host maps a file by MIME type, so an entry that declared
  only `mimetypes` stays distinguishable from one that declared nothing.
- **command-icon-string-form-only**: a command entry's `icon` MUST decode a
  plain string icon path, and MUST decode to absent — dropping the icon
  with no decoding failure recorded anywhere — when the manifest supplies
  VS Code's object form (`{ light, dark }`) instead, so a themed icon never
  costs the command its `command`, `title`, `category`, or `enablement`.
- **keybinding-args-not-carried**: a keybinding entry MUST expose only
  `command`, `key`, `mac`, and `when`; it MUST NOT carry a manifest's
  `args` field, because nothing in the extension host's command dispatch
  accepts arguments today.
- **menu-item-strict-shape**: a menu item entry MUST require `command` as
  a string and MUST treat `when`, `group`, and `alt` as ordinary optional
  fields.
- **configuration-title-id-order-independently-tolerant**: a configuration
  section's `title`, `id`, and `order` MUST each decode independently and
  tolerantly, so a wrong-typed value in any one of the three (e.g. `order`
  spelled as the string `"0"`) MUST resolve only that field to absent,
  never prevent the other two fields or `properties` from decoding.
- **configuration-properties-per-property-isolation**: a configuration
  section's `properties` MUST decode each property key independently and
  tolerantly; a property whose value cannot decode as a configuration
  property MUST be dropped from the dictionary while every sibling property
  in the same section MUST still decode.
- **configuration-property-type-single-or-union**: a configuration
  property's declared type MUST decode a single JSON Schema type name as a
  single-type value, and MUST decode a JSON array of type names as a union
  of type names with every non-string member dropped.
- **configuration-property-effective-type-collapse**: a configuration
  property's effective type MUST return the single non-`"null"` member of
  a union when exactly one distinct such member exists, and MUST return
  absent when zero or more than one distinct non-`"null"` member remains;
  for a single-type value it MUST return that name unchanged, and for an
  absent declared type it MUST return absent.
- **configuration-property-every-field-independently-tolerant**: every one
  of a configuration property's decoded fields (`type`, `default`,
  `description`, `markdownDescription`, `enum`, `enumDescriptions`,
  `markdownEnumDescriptions`, `enumItemLabels`, `scope`, `order`,
  `minimum`, `maximum`, `deprecationMessage`, `markdownDeprecationMessage`,
  `editPresentation`) MUST decode independently and tolerantly, so a
  wrong-typed value in any one field MUST resolve only that field to
  absent, never fail the property or its section.
- **configuration-property-enum-item-labels-nullable-elements**: a
  configuration property's `enumItemLabels`, when present, MUST decode as a
  list of optional strings — an individual element may be JSON `null`,
  preserved as absent at that position, rather than failing the whole
  list.
- **view-identity-strict-decorations-tolerant**: a view entry's `id` and
  `.name` MUST decode strictly — a view missing either MUST fail that array
  element, via `lenient-dictionary-element-isolation`; its `when`, `type`,
  `icon`, `contextualTitle`, `visibility`, and `initialSize` MUST each
  decode independently and tolerantly of a wrong type.
- **view-unreadable-keys-recorded-per-field**: a view entry's set of
  unreadable keys MUST list the name of every optional field that was
  present in the manifest but could not be decoded to its declared type; a
  key that was absent entirely MUST NOT appear in that set.
- **view-explicit-null-treated-as-withdrawn**: a view entry's
  tolerant-field decoding MUST treat an explicit JSON `null` for an
  optional field as the field being withdrawn — resolving to absent and NOT
  adding the key to the unreadable-keys set — distinct from a
  present-and-unreadable value, which resolves to absent AND adds the key.
- **view-unreadable-keys-not-encoded**: a view entry's set of unreadable
  keys MUST NOT be included when the view is encoded back to JSON.
- **view-container-strict-identity-tolerant-decorations**: a view
  container entry's `id` and `.title` MUST decode strictly; its `icon` and
  `when` MUST each decode independently and tolerantly, resolving to
  absent on a type mismatch without failing the container and with no
  tracking equivalent to a view's unreadable-keys set.
- **language-model-tool-plain-shape**: a language-model-tool entry MUST
  decode `name`, `displayName`, `modelDescription`, `toolReferenceName`,
  `inputSchema`, `tags`, and `canBeReferencedInPrompt` with no custom
  per-field recovery of its own; a malformed field anywhere in one tool
  entry MUST fail only that entry's array element, via
  `lenient-array-element-isolation`, never a sibling tool.
- **manifest-and-contributions-are-thread-safe**: a manifest, its
  contributions value, and every nested type MUST each be immutable,
  comparable values safe to use across any concurrency boundary; decoding
  MUST be a synchronous, side-effect-free function of the decoder handed to
  it, with no file, network, or process access anywhere in this component,
  so a decoded value MAY be passed freely across concurrency domains and
  MAY be decoded concurrently by independent callers without coordination.

