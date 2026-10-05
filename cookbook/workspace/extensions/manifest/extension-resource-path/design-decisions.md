
- **Decision**: a single `resolve` function is shared by all four
  extension-declared-path call sites — snippets, a theme's `path`, a
  theme's `include`, and the host's `browser` entry point — rather than
  each contribution point re-deriving its own containment check.
  **Rationale**: the source's own header comment states that three of the
  four call sites were missing the escape half of the check before this
  type existed, each having re-derived the base URL "in its own words,"
  which let the same `../../../.ssh/config` traversal escape through any of
  them except the one that already checked for it.
  **Approved**: pending
- **Decision**: both sides of a containment comparison are canonicalized
  identically — symlinks resolved, then standardized — rather than
  canonicalizing only the untrusted candidate.
  **Rationale**: the source's comment on `canonicalDirectory` gives both
  failure directions concretely: on macOS the temporary directory alone is
  a symlink (`/var` mapping to `/private/var`), so canonicalizing only one
  side would either refuse every legitimate path under a symlinked root or
  accept an escape through a symlink planted inside the extension,
  depending on which side went uncanonicalized.
  **Approved**: pending
- **Decision**: `canonicalChild(_:of:)` canonicalizes only the parent
  directory and appends the component, rather than building the full child
  path first and canonicalizing that.
  **Rationale**: symlink resolution only drops a leading `/private` when
  the remaining path still names something that exists on disk, so
  canonicalizing a not-yet-created child — as an install-directory guard
  needs to, before the directory it is about to create exists — yields a
  different root than canonicalizing its already-existing parent. The
  source's comment states this literally refused every install into a
  macOS temporary directory, or a home on another volume, by name, before
  `canonicalChild` existed to canonicalize only the part that is actually
  there.
  **Approved**: pending
- **Decision**: `url(_:isContainedIn:)` treats the base directory itself as
  not contained in itself, rather than allowing the candidate to equal the
  base.
  **Rationale**: the source's own comment states the consequence of
  allowing equality directly: a declared path of `"."` resolves to the
  directory itself, and treating that as "contained" would hand a caller
  the directory to open as if it were a file.
  **Approved**: pending
- **Decision**: `InstalledContentLocation` derives locations but never
  validates its own string inputs (`appName`, `subdirectory`, `name`) for
  emptiness or shape, leaving that entirely to callers.
  **Rationale**: per `application-support-appname-validation`, the source's
  own doc comment makes a non-empty `appName` a caller precondition rather
  than a guard in the function, and no
  test in `InstalledContentLocationTests.swift` exercises an empty
  `appName`. Documented here rather than silently left as an assumption,
  per the source's own naming of the risk.
  **Approved**: pending

