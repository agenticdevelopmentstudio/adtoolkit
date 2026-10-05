
- **Empty path is the host document, not a missing file**: a URL whose
  decoded path is the empty string or exactly `"/"` (for example
  `agentic-webview://panel-1` or `agentic-webview://panel-1/`) resolves to
  `.hostDocument` before any file resolution or containment check runs, and
  this is true even when `localResourceRoots` is empty. MUST.
- **Boundary — the root directory itself versus a child of it**: a candidate
  equal to a declared root, byte for byte after canonicalization, is refused
  because the resource-path containment check requires the candidate's
  path-component count to be strictly greater than the root's; a candidate
  one path component below the same root is allowed. MUST.
- **Absent scheme on the incoming URL**: when the incoming URL has no
  scheme at all (a relative-looking URL string), the unexpected-scheme
  failure MUST carry the empty string rather than any placeholder or a
  substituted word. MUST.
- **Absent host on the incoming URL**: when the incoming URL has no host,
  the URL decision MUST treat the declared panel as the empty string before
  comparing it to the caller-supplied panel identifier, so a caller-supplied
  panel identifier of `""` is the only value such a URL could ever match.
  MUST.
- **Concurrent access**: this component holds no mutable stored state —
  every operation is a pure computation over its own arguments — so calling
  any of them concurrently, from any execution context, with independent or
  shared resource-root arrays, requires no synchronization of its own. MUST.
- **A symlink planted inside a declared root**: because both the candidate
  and each root are canonicalized (symlinks resolved, then standardized)
  before comparison, a candidate reached through a symlink that itself
  points outside the root is refused even though the declared path string
  contains no `..` segment; this follows from the resource-path containment
  check's documented symmetric-canonicalization rule, which
  `containment-delegation` inherits rather than re-deriving. MUST.
- **A panel id that cannot be spelled as a URL authority**: URL construction
  returns a fixed, well-formed fallback location instead of trapping or
  producing nothing; that fallback is itself then refused by the URL
  decision on a later call, because it names a location outside the
  `agentic-webview` scheme. SHOULD (see Design Decisions for why a trap was
  rejected).
- **Error states**: the only three defined failures are the three failure
  cases this component defines, each raised synchronously and exactly once
  per call to the URL decision; no error is ever swallowed inside this
  component. What a caller does with a raised failure — logging it, or
  communicating a load failure back to the webview — is outside this
  component's contract. MUST.
- **Offline / disconnected state**: not applicable. Every operation reads
  only URL structure and local file-system symlink metadata; there is no
  networking in this component and therefore no connectivity state to lose
  mid-operation.
- **Cancellation and timeout**: the URL decision, building the
  host-document URL, and naming a file's resource URL define no timeout and
  no cancellation, because every call runs to completion synchronously
  without suspension. A slow or unresponsive volume underneath a declared
  root blocks the caller for as long as symlink resolution takes, with no
  escape hatch defined in this component. Stated as fact, per the
  absent-feature rule — not a marker, since nothing in the purpose of a
  synchronous, pure decision function calls for one.

