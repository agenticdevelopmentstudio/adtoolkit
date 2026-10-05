
- **Data collected**: not device- or user-identifying telemetry, but this
  component is the exact shape of what a webview panel persists across a
  quit: the panel's `title` and whatever opaque `state` string the
  extension's page last passed to `setState`. What that `state` string
  contains is entirely up to the extension's page — it could be as
  innocuous as a scroll position or as sensitive as a form draft — and this
  component has no visibility into which, since it is carried as opaque
  text and never parsed.
- **Storage**: this component itself holds its four fields only in memory;
  it writes nothing to disk directly. Its encoded result is what a caller
  (the panel serializer) passes to the pane-state store for actual
  persistence, which is outside this component's own contract.
- **Transmission**: none performed by this component — it does no
  networking.
- **Retention**: for as long as whichever caller holds the decoded value or
  its encoded string; this component itself retains nothing once a call to
  encode or decode returns.

