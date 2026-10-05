
- **error-case**: a typed escape error MUST be a comparable value type with
  exactly one case: an escape failure carrying the exact string the caller
  declared and the exact resolved destination path.
- **error-message**: the escape error MUST provide a human-readable
  description that names both the exact string the caller declared and the
  exact resolved destination path, in the form "The path (declared, in
  curly quotes) resolves to (resolved), which is outside the extension's
  own directory."
- **single-base-resolve**: resolving a path against a single directory
  MUST resolve `declared` against `directory` and require the result be
  contained within that same `directory`, by delegating to the
  two-directory resolve operation with `directory` supplied as both the
  base and the root.
- **candidate-construction**: the two-directory resolve operation MUST
  build its candidate location by constructing a file path from `declared`
  relative to the canonicalized base directory, then applying symlink
  resolution followed by path standardization, in that order.
- **escape-refusal**: the two-directory resolve operation MUST fail with
  the escape error when the constructed candidate is not contained in the
  canonicalized root directory, and MUST return the candidate unchanged
  when it is.
- **error-payload-fidelity**: the escape error's declared value MUST be
  exactly the string the caller passed in, unmodified by trimming or
  normalization, and its resolved value MUST be the fully canonicalized
  candidate's path string.
- **directory-flag-forcing**: canonicalizing a directory MUST re-derive
  its argument as a location explicitly marked as a directory before
  resolving symlinks and standardizing, so that a location carrying no
  directory marking is still treated as a directory rather than resolved
  against its parent.
- **symmetric-canonicalization**: both the base (or root) side and the
  candidate side of a containment decision MUST be produced by resolving
  symlinks and then standardizing, so that a directory reached through a
  symlink compares equal to the same directory reached directly.
- **child-of-nonexistent-parent**: deriving a not-yet-existing child
  location MUST canonicalize only the parent directory (which is assumed
  to exist), then append the child name and standardize the result; it
  MUST NOT canonicalize the combined, not-yet-existing path as a whole.
- **containment-strictness**: the containment check MUST return true if
  and only if the candidate's path-component count is strictly greater
  than the base's, and the leading path components of the candidate — as
  many as the base has — equal the base's path components exactly, element
  by element; a directory MUST NOT be considered contained in itself.
- **component-wise-comparison**: the containment check MUST compare path
  components, and MUST NOT treat the base's path as a string prefix of the
  candidate's path, so that a sibling directory whose name merely starts
  with the base's name (for example a directory named with the base's name
  plus `-evil` appended) is never mistaken for a descendant.
- **containment-inputs-uncanonicalized**: the containment check MUST NOT
  itself resolve symlinks or standardize either argument; it MUST operate
  only on whichever path components its two location arguments already
  carry, leaving canonicalization to the caller.
- **application-support-composition**: composing the application-support
  location for an app MUST return the user domain's Application Support
  directory with the app's name appended and then the subdirectory name
  appended, in that order, and MUST return absent when the user domain has
  no Application Support directory to report.
- **home-dot-directory-composition**: composing the home dotfolder
  location MUST return the home directory with one additional path
  component consisting of a literal `.` immediately followed by the
  folder's name.
- **home-directory-default**: the home dotfolder composition's
  home-directory parameter MUST default to the process's own home
  directory when the caller supplies no override.
- **stateless-synchronous-operation**: every operation in this component
  and the installed-content-location helper MUST be a synchronous function
  or a computed value operating only on its arguments; neither exposes any
  stored state, and neither can be instantiated, so neither can carry
  state between calls.
- **safe-across-any-concurrency-domain**: none of this component, the
  installed-content-location helper, or the escape error requires
  exclusive access to a particular thread or task. Because every value
  used here (a string, a location, a boolean) is itself safe to share
  across concurrency boundaries, and none of the three holds mutable
  stored state reachable from more than one call, every operation MUST be
  safe to invoke from any concurrency domain, concurrently, without
  additional synchronization.
- **filesystem-side-effects**: resolving a path against a single
  directory, the two-directory resolve operation, and canonicalizing a
  directory MUST consult the file system (through symlink resolution) to
  canonicalize a path, but no operation in this component MUST create,
  delete, or write to any file or directory.
- **application-support-appname-validation**: composing the
  application-support location performs no check that the app's name is
  non-empty before composing the path. This is a stated caller
  precondition — an empty component "collapses the path onto the shared
  Application Support/subdirectory and silently widens the search to
  every app's content of that kind" — and callers are expected to derive
  the name through something that cannot answer an empty string; today the
  only caller always supplies a non-empty display name.

