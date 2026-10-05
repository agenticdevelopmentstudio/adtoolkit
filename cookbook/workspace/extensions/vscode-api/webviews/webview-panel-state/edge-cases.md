
- **Null and empty input**: decoding this component from an empty string
  MUST fail, as MUST decoding a `state` value that is present but is the
  empty string `""` — the latter decodes successfully and round-trips,
  since `state` is an opaque string with no defined "empty means absent"
  rule; only a genuinely absent `state` key means absent. MUST.
- **Boundary values — the four fields' "nothing supplied" cases**: `title`
  absent decodes to `""`; `state` absent decodes to absent; `options`
  absent decodes to the safe, no-scripts posture; `viewType` absent is the
  one boundary that is refused outright rather than defaulted, because
  nothing can safely stand in for the serializer identity it names. MUST.
- **Concurrent access**: this component and the webview panel options it
  carries are both immutable value types with no shared mutable storage, so
  encoding and decoding MAY be called concurrently, from any number of
  independent execution contexts, against any number of independent values,
  with no synchronization required. This is a property of the component's
  declared immutability, not a marker. MUST.
- **Error states**: the only two failure paths this component defines are
  encoding failing with the "encoded text is not UTF-8" error condition (the
  source's own documentation calls this case unreachable in practice, since
  the encoder's output is UTF-8 by definition of JSON, and states the
  alternative — crashing instead — as strictly worse) and decoding
  propagating whatever error decoding raises for malformed or
  under-specified data. Neither path is caught or swallowed inside this
  component; both are the caller's to handle. MUST.
- **Offline / disconnected state**: not applicable. This component performs
  no networking of any kind; it only encodes to and decodes from an
  in-memory string, so there is no connectivity state to lose
  mid-operation.
- **Downgrade and forward compatibility**: data written by a newer build
  that added a field this build does not know about MUST still decode
  (**unknown-fields-ignored**), and data written by an older build that
  predates `options` MUST decode to the safe posture rather than failing
  (**missing-options-default-safe**) — both are read-time recovery from a
  schema older or newer than the reader's, stated here because neither is a
  null/empty/boundary case in the ordinary sense. MUST.

