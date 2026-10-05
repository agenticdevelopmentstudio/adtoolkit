
- **stored-shape**: This component MUST have exactly four fields: `viewType`
  (a string), `title` (a string), `state` (a string, optional), and `options`
  (a webview panel options value).
- **memberwise-construction**: Constructing this component from its four
  fields MUST assign each argument directly to its like-named field,
  performing no derivation, defaulting, or validation.
- **owning-extension-not-stored**: This component MUST NOT store the
  identifier of the extension that owns the panel; the owning extension is
  derivable from `viewType` (the activation event
  `onWebviewPanel:<viewType>`), and a second, independently-stored copy of a
  derivable fact is one that can disagree with the first.
- **sorted-key-encoding**: Encoding this component MUST produce its keys in a
  fixed, sorted order, so that an unchanged panel encodes to an unchanged
  string and a change-notifying store stays quiet when nothing actually
  changed.
- **utf8-encode-guarantee**: Encoding this component MUST construct its
  returned string from the encoded bytes interpreted as UTF-8, and MUST fail
  with a defined "encoded text is not UTF-8" error condition if that
  interpretation fails, rather than crashing on the conversion.
- **decode-entry-point**: Decoding this component from a stored string MUST
  decode it from that string's UTF-8 bytes, propagating whatever error
  decoding raises rather than catching or wrapping it.
- **round-trip-fidelity**: An instance of this component passed through
  encoding and then decoding MUST decode to a value equal to the original,
  for every combination of its four fields.
- **state-carried-verbatim**: the `state` field MUST be encoded and decoded
  as an opaque string value, never parsed, re-serialized, or otherwise
  interpreted as structured data by this component, so that whatever text
  the extension's page last passed to `setState` — including text that is
  itself JSON, contains escaped quotes, embedded newlines, non-ASCII
  characters, or a closing script-element sequence — round-trips byte for
  byte.
- **absent-state-omits-key**: Encoding this component MUST omit the `state`
  key entirely from the encoded data when `state` is absent, rather than
  encoding a null value — keeping "the page never called `setState`"
  distinct from "the page saved the text `null`".
- **missing-view-type-refused**: Decoding this component MUST require a
  `viewType` key, so that data with no `viewType` key fails to decode rather
  than decoding with a defaulted or empty value.
- **missing-title-defaults-empty**: Decoding this component MUST decode
  `title` as an empty string when the source data has no `title` key, rather
  than failing to decode.
- **missing-options-default-safe**: Decoding this component MUST decode
  `options` as the fully-absent safe posture — no scripts, no forms, the
  default resource roots — when the source data has no `options` key, rather
  than failing to decode or guessing a more permissive value.
- **unknown-fields-ignored**: Decoding this component MUST ignore any key not
  named `viewType`, `title`, `state`, or `options`, so that data written by a
  newer build with an additional field (for example a hypothetical
  `iconPath`) still decodes successfully in a build that does not know that
  field.
- **malformed-text-refused**: Decoding this component from a stored string
  MUST fail for input that is not an object containing at least a string
  `viewType` — including an empty string, non-JSON text, truncated JSON, an
  array, and a bare string literal.
- **fixed-coding-keys**: Encoding and decoding this component MUST both use
  the same fixed key set (`viewType`, `title`, `state`, `options`), so the
  field names and the wire key names never diverge independently of each
  other.
- **safe-for-concurrent-access**: Because this component holds no mutable
  stored state — every field is fixed once constructed, and each field's own
  type is itself safe for concurrent access — a value of this component MUST
  be safe to pass across concurrent execution contexts without additional
  synchronization.
- **empty-view-type-validation**: Decoding MUST accept a `viewType` that is present as an empty string: only an absent key is refused (**missing-view-type-refused**), because the key is required to be a string, not a non-empty one. The hazard that justifies refusing the absent case, handing the panel to whichever provider answers to the empty string, applies equally to an explicit empty string, which is not guarded (see the pending design decision on empty view types).

