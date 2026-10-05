
- **entry-point-delegation**: Building sections for a manifest MUST
  delegate to the lower-level sections builder, passing the manifest's
  `contributes.configuration` (or an empty list when absent) as the
  configuration list, the manifest's identifier as the owning extension,
  the manifest's display name (or its bare name when no display name is
  declared) as the fallback title, and the manifest's recorded decoding
  failures (or an empty list when none) as the decoding-failures list.
- **undeclared-configuration**: when the configuration list is empty and
  the decoding-failures list contains no entry whose key equals
  `"contributes.configuration"`, building sections MUST return the
  undeclared outcome with no sections.
- **unreadable-configuration**: when the configuration list is empty and
  the decoding-failures list contains at least one entry whose key equals
  `"contributes.configuration"`, building sections MUST return the
  unreadable outcome carrying that first entry's reason, with no sections.
- **declared-when-nonempty-input**: when the configuration list is
  non-empty, the returned declaration MUST be the declared outcome, even
  when filtering removes every section and the resulting sections list is
  empty — a declared outcome with no sections and the undeclared outcome
  MUST remain distinguishable results.
- **empty-section-dropped**: a configuration entry whose declared
  properties are empty MUST produce no settings section and no note.
- **sorted-property-iteration**: within one section, properties MUST be
  visited and classified in ascending lexicographic order of key, never in
  whatever order the decoded properties happen to be stored in, because
  that order is not guaranteed stable and would otherwise leak into the
  notes list.
- **duplicate-key-first-wins**: when more than one section (processed in
  configuration-list order, keys within a section in sorted order)
  declares the same property key, only the first-encountered declaration
  MUST become a row; every later declaration of that key MUST be skipped
  and MUST produce a duplicate-key note for that key whose detail is
  exactly "already declared by an earlier section; this declaration is
  ignored".
- **section-emptied-by-duplicates-dropped**: a section every one of whose
  properties was claimed by an earlier section MUST produce no settings
  section, and MUST NOT produce a missing-section-title note, even when the
  section itself declared no title — the emptiness check MUST run before
  title resolution for exactly this reason.
- **section-title-resolution**: a surviving section's title MUST be its
  own declared title when that value is non-empty; otherwise it MUST be
  the fallback title, and a missing-section-title note MUST be recorded
  whose key is the resolved fallback title and whose detail is exactly
  "section {index} declared no title; using \"{fallbackTitle}\"", where
  index is the section's zero-based position in the decoded configuration
  list.
- **section-ordering**: the declaration's sections MUST be sorted so a
  section with a smaller declared order precedes one with a larger
  declared order; a section with a declared order MUST precede one with
  none; when neither rule distinguishes two sections, the one with the
  lexicographically smaller title MUST precede; when titles are equal too,
  the section that appeared earlier in the decoded configuration list MUST
  precede.
- **setting-ordering**: within one section, the settings MUST be sorted by
  the same rule applied to each setting's own declared order, with the
  final tiebreak being the setting's own key in ascending order rather
  than a title or list position, because keys are unique within one
  section.
- **storage-name-format**: computing a setting's storage name MUST return
  exactly the string `"extensions.{identifier}.{key}"`, and a setting
  row's own storage name MUST equal the result of that computation for
  that setting's own key and the owning extension's identifier.
- **setting-key-verbatim**: a setting row's key MUST equal the manifest's
  dotted property key exactly as declared, with no namespace stripped and
  no case change.
- **enum-string-choice**: a property whose `enum` is declared, non-empty,
  and (after dropping any `null` members) contains only JSON string
  members MUST classify as the choice kind.
- **enum-label-positional**: each produced option's label MUST be the
  corresponding `enumItemLabels` entry at the member's original,
  pre-null-filter index when that entry is present and non-null, and MUST
  otherwise be the option's own value.
- **enum-null-member-dropped**: a `null` member of a declared `enum` MUST
  be omitted from the resulting options and MUST NOT by itself prevent the
  property from classifying as the choice kind.
- **enum-default-matches**: when `default` is a JSON string equal to one
  of the enum's retained, non-null string members, that value MUST be
  selected with no note recorded for the default.
- **enum-default-null**: when `default` is the JSON literal `null`, a
  default-type-mismatch note with detail "default is null; the first
  member stands in" MUST be recorded, and the first retained member MUST
  be selected.
- **enum-default-not-member**: when `default` is present, is not `null`,
  and either is not a JSON string or is a string absent from the enum's
  retained members, a default-not-in-enum note MUST be recorded quoting
  the default's raw text, a new option whose label and value both equal
  that raw text MUST be inserted at the front of the options list, and it
  MUST be selected.
- **enum-default-missing**: when `enum` is declared and classifies as the
  choice kind but `default` is absent entirely, a missing-default note
  with detail "no default; the first member stands in" MUST be recorded
  and the first retained member MUST be selected.
- **enum-descriptions-dropped**: when a property classifies as the choice
  kind and declares `enumDescriptions` or `markdownEnumDescriptions`, an
  enum-descriptions-dropped note MUST be recorded regardless of which
  default-resolution branch ran.
- **enum-mixed-falls-to-type**: when `enum` is declared and non-empty but
  at least one non-null member is not a JSON string, a non-string-enum
  note MUST be recorded and classification MUST proceed using the
  property's effective type (or default-based inference) instead of the
  enum.
- **boolean-classification**: a property whose effective type is
  `"boolean"` MUST classify as the toggle kind.
- **boolean-default-fallback**: for a toggle classification, a missing
  `default` MUST record a missing-default note ("no default; false stands
  in") and use `false`; a `default` that is not a JSON boolean MUST record
  a default-type-mismatch note and use `false`.
- **string-classification**: a property whose effective type is `"string"`
  MUST classify as the text kind, with multiline true if and only if
  `editPresentation` equals `"multilineText"`.
- **string-default-fallback**: for a text classification, a missing
  `default` MUST record a missing-default note ("no default; the empty
  string stands in") and use the empty string; a `default` that is not a
  JSON string MUST record a default-type-mismatch note and use the empty
  string.
- **number-classification**: a property whose effective type is `"number"`
  MUST classify as the number kind, carrying `minimum`/`maximum` through
  unmodified when declared, and inventing neither bound when absent.
- **integer-classification**: a property whose effective type is
  `"integer"` MUST classify as the integer kind; a missing `default` MUST
  record a missing-default note and use `0`; a `default` that is not a
  whole JSON number MUST record a default-type-mismatch note and use `0`.
- **integer-bounds-rounding**: for an `"integer"` property, a declared
  `minimum` MUST be rounded up and a declared `maximum` MUST be rounded
  down to the nearest whole number before either is treated as a bound,
  because a bound that widened when rounded could let a clamp store a
  value the schema forbids.
- **bounds-contradiction-dropped**: when both `minimum` and `maximum` are
  present for a `"number"` or `"integer"` property (after any integer
  rounding) and `minimum` exceeds `maximum`, both bounds MUST be dropped —
  treated as absent — and a contradictory-bounds note naming both values
  MUST be recorded.
- **default-clamped-to-bounds**: when both bounds are present and agree,
  and the resolved default lies outside them, the default MUST be clamped
  to the nearer bound and a default-out-of-range note naming the original
  default and the bound used MUST be recorded; this clamp MUST run only
  after bounds have already been checked for agreement.
- **array-object-to-json**: a property whose effective type is `"array"`
  or `"object"` MUST classify as the json kind, with default equal to the
  pretty-printed JSON text of the declared default, and MUST record no
  note for this classification — it is the type's intended destination,
  not a compromise.
- **unrenderable-type-fallback**: a property whose effective type is any
  value other than `"boolean"`, `"string"`, `"integer"`, `"number"`,
  `"array"`, or `"object"` MUST classify as the json kind and MUST record
  an unrenderable-type note naming the type.
- **mixed-union-fallback**: when a property's declared `type` is a union
  whose non-null members do not collapse to exactly one name (so the
  effective type is absent), classification MUST record a
  mixed-union-type note naming the union's members and MUST classify as
  the json kind using the declared default's JSON text.
- **no-type-inference**: when a property declares no `type` at all (not a
  union, and the effective type is absent), classification MUST be
  inferred from the JSON type of `default`: a boolean default classifies
  as toggle with no note; a whole-number default classifies as integer
  (bounds handled per `integer-bounds-rounding`); a non-whole-number
  default classifies as number; a string default classifies as text
  (honouring `editPresentation`); an array or object default classifies as
  json with no note; a `null` default classifies as json and records an
  unrenderable-type note ("no type, and a null default says nothing about
  one"); and an entirely absent default classifies as json (rendering
  `"null"`) and records an unrenderable-type note ("no type, no enum and
  no default").
- **json-escape-hatch-text**: rendering a value's JSON text MUST produce
  pretty-printed, key-sorted JSON with forward slashes left unescaped; a
  whole-number JSON value MUST render without a trailing `.0`; and an
  absent input MUST render as the JSON literal `null`.
- **deprecation-appended**: when a property declares `deprecationMessage`,
  or, absent that, `markdownDeprecationMessage`, the resulting setting
  row's explanation MUST append that message after any
  `description`/`markdownDescription` body separated by one blank line, or
  stand alone when no body exists, and a deprecated note carrying that
  message as its detail MUST be recorded, independent of what kind the
  property classified as.
- **explanation-source**: a setting row's explanation body MUST be
  `description` when present, and otherwise `markdownDescription` treated
  as plain text — its Markdown syntax MUST NOT be rendered or stripped,
  only carried through verbatim, because nothing that displays this string
  renders Markdown.
- **setting-order-field**: a setting row's order MUST equal the property's
  own declared `order`, and that value MUST already have determined the
  setting's position within its section's settings list per
  `setting-ordering`.
- **thread-safe-value-types**: an option, a setting's kind, a setting row,
  a settings section, a note, and the declaration MUST each be immutable,
  comparable values usable safely from any thread, so a caller MAY pass
  any of them across a concurrency boundary with no additional
  synchronization.
- **pure-no-side-effects**: classification MUST hold no mutable state of
  its own, and building sections and computing a storage name MUST NOT read a setting's stored value, write one, or perform any file, network,
  or window-system side effect — each call's only observable effect MUST
  be its return value.

