
- **scheme-constant**: this component's scheme constant MUST equal the
  literal string `"agentic-webview"`. This is a storage format: an extension
  that persists a resource URI through `setState` writes this string into
  the pane state database, and a restored panel hands it straight back, so
  changing the value orphans that persisted state silently.
- **error-case**: this component MUST define exactly three distinct failure
  cases: an unexpected-scheme failure carrying the scheme string that was
  actually found, an unexpected-panel failure carrying the declared panel
  identity and the expected panel identity, and an outside-declared-roots
  failure carrying the resolved candidate path.
- **error-message**: this component MUST produce, for each failure case, one
  of exactly these three sentence forms as its description text,
  substituting the case's payload verbatim: for the unexpected-scheme
  failure, "A webview asked for" the scheme in curly quotes "which is not
  the webview scheme."; for the unexpected-panel failure, "A webview asked
  for panel" the declared value in curly quotes "from panel" the expected
  value in curly quotes; for the outside-declared-roots failure, "A webview
  asked for" the resolved value "which is outside its localResourceRoots."
- **target-type**: the result of a URL decision MUST be one of exactly two
  outcomes: the panel's own host document (no payload), or a specific file
  (carrying its location).
- **host-document-url**: building the panel's host-document URL MUST return
  the URL built by composing the scheme, the given panel identifier as
  authority, and the path `"/"`.
- **resource-url-naming-only**: naming a file's resource URL MUST return the
  URL built by composing the scheme, the given panel identifier as
  authority, and the file's path as the path, performing no existence
  check, no symlink resolution, and no containment check against any root;
  naming a file this way is not permission to read it.
- **percent-encoding-round-trip**: URL construction (both building the
  host-document URL and naming a file's resource URL) MUST percent-encode
  the panel identifier and path values it composes from, so that a path
  containing a space, a `#`, a `%`, or a non-ASCII character round-trips
  through the URL decision to the same file it named.
- **leading-slash-normalization**: URL construction MUST prefix the composed
  path with `/` when the caller-supplied path does not already start with
  one, so that the URL remains well-formed once an authority (the panel
  identifier) is present.
- **unroutable-fallback**: URL construction MUST return a fixed, well-formed
  fallback location in place of failing to build a URL at all, rather than
  trapping or returning nothing, for the case where the given panel
  identifier cannot be spelled as a URL authority at all.
- **scheme-validation-first**: the URL decision MUST check the URL's scheme
  against this component's scheme constant before any other check, and MUST
  fail with an unexpected-scheme failure carrying the URL's scheme (or the
  empty string when the scheme is absent) when they do not match exactly.
- **panel-validation-second**: after the scheme check passes, the URL
  decision MUST decode the URL's host with percent-encoding removed
  (treating an absent host as the empty string) and MUST fail with an
  unexpected-panel failure, carrying that decoded value as the declared
  identity and the caller-supplied panel identifier as the expected
  identity, when the two differ, before any file-path resolution is
  attempted.
- **host-document-detection**: after the scheme and panel checks pass, the
  URL decision MUST return the host-document outcome, with no file-path
  resolution and no containment check, when the URL's decoded path is the
  empty string or exactly `"/"`.
- **candidate-canonicalization**: for a path that is neither empty nor
  `"/"`, the URL decision MUST build the candidate file location by
  constructing it from the decoded path, then resolving symlinks, then
  standardizing the result, applying exactly these three steps in this
  order before any containment decision.
- **containment-delegation**: the URL decision MUST decide whether the
  candidate is allowed by delegating to the resource-path containment check
  against the canonicalized form of each declared root, in the order the
  array supplies them, rather than comparing paths as strings or
  re-implementing containment.
- **first-matching-root-wins**: the URL decision MUST return the file
  outcome as soon as any one declared root contains the candidate; it MUST
  NOT require containment in every declared root.
- **empty-roots-refuses-every-file**: when the set of declared resource
  roots is empty, the URL decision MUST fail with an outside-declared-roots
  failure for every non-host-document path, treating no declared root as no
  file access at all.
- **containment-failure-payload**: when no declared root contains the
  candidate, the URL decision MUST fail with an outside-declared-roots
  failure carrying the fully canonicalized candidate's resolved path (post
  symlink-resolution and standardization), not the raw path the URL
  carried.
- **stateless-re-derivation**: the URL decision MUST compute its answer
  solely from its given arguments on every call; it MUST NOT consult or
  maintain any cache, table, or other state mapping a panel id or a URL to
  a previously computed answer, so a root narrowed between two requests
  narrows the second request's outcome as well.
- **safe-for-concurrent-access**: this component holds no mutable stored
  state — every operation is a pure computation over its own arguments —
  so every operation MUST be safe to invoke from any execution context,
  concurrently, without additional synchronization.
- **no-filesystem-mutation**: the URL decision MUST consult the file system
  only to resolve symlinks while canonicalizing the candidate and the
  declared roots; this component MUST NOT create, delete, write, or read
  the contents of any file or directory.

