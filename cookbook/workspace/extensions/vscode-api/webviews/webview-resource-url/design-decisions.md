
- **Decision**: the panel id is spelled as the URL's authority (host)
  rather than as a path segment.
  **Rationale**: the source's own header comment states this is what makes
  two panels two WebKit origins, so one extension's panel cannot read
  another's storage; a path-segment encoding would not produce that origin
  boundary at all.
  **Approved**: pending
- **Decision**: the file path is spelled into the URL as the file's own
  absolute path, rather than as an opaque identifier looked up in a table
  the handler maintains.
  **Rationale**: the source's comment states a request this way carries
  everything needed to answer it, so containment is re-derived from the URL
  on every request instead of trusting a promise about how the URL was
  built, and the handler holds no id-to-file table that could drift out of
  sync with it.
  **Approved**: pending
- **Decision**: an empty path is defined as the panel's own host document,
  not an error and not a file lookup.
  **Rationale**: the source's comment on the scheme states the host
  document still needs a real URL, because a document loaded without one
  gets an opaque origin and loses both storage and any hope of a coherent
  CSP; treating the empty path as a file path would have nothing on disk to
  resolve it to.
  **Approved**: pending
- **Decision**: containment against `localResourceRoots` is delegated
  component-wise to `ExtensionResourcePath.url(_:isContainedIn:)` rather
  than re-implemented here.
  **Rationale**: `ExtensionResourcePath`'s own header comment names this as
  its reason for existing at all — the same rule hand-rolled at other call
  sites had missed the escape half of the check — and the source's comment
  on this file states plainly that `localResourceRoots` is the fifth call
  site of that rule, not a second implementation of it.
  **Approved**: pending
- **Decision**: an unrepresentable panel id produces a fixed fallback URL
  (`URL(fileURLWithPath: "/")`) rather than a trap or a `nil` return.
  **Rationale**: the source's comment states that trapping would turn an
  unrepresentable id into a crash in the host, and that the fallback is
  itself refused by `target(of:)` on sight because it is not in the webview
  scheme — a resource that cannot be named is a resource the page cannot
  have, which the comment calls the right outcome.
  **Approved**: pending
- **Decision**: `target(of:panelID:localResourceRoots:)` re-derives its
  answer from its arguments on every call rather than caching a prior
  decision for a URL or a panel.
  **Rationale**: the source's comment states the roots are read from the
  handler's current value rather than captured, so an extension that
  narrows `localResourceRoots` narrows them for requests already in flight,
  not only for the next page; a cached answer would defeat that.
  **Approved**: pending

