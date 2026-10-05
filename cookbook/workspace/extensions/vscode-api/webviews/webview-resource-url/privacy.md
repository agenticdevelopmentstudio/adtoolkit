
- **Data collected**: none in the sense of device- or user-identifying
  telemetry. However, the resolved payload of an outside-declared-roots
  failure, and every URL that naming a file's resource URL or building the
  panel's host-document URL constructs, embed the absolute local
  file-system path of a file inside the extension's own directory tree — a
  path that can include the local account's home-directory name when a
  declared root sits under it.
- **Storage**: none performed by this component. This component writes
  nothing to disk; a caller that persists a resource URI through `setState`
  does so outside this component.
- **Transmission**: none performed directly by this component — it does no
  networking. A URL or failure this component produces may later be handed
  to the webview or logged by a caller; how far that propagates is outside
  this component.
- **Retention**: for the lifetime of whichever value — a decision outcome, a
  failure, or a constructed URL — the caller holds; this component itself
  retains nothing once a call returns.

