
- **Null/empty input**: an empty JSON object `{}` decoded as a manifest MUST
  fail (extension-manifest-001). A manifest with no `contributes` key at
  all MUST behave identically to the empty contributions value
  (**contributions-absent-vs-empty-equivalence**). `enumItemLabels: []`
  (present but empty, not absent) MUST decode to an empty list, not
  absent.
- **Boundary/malformed values**: `activationEvents`/`extensionKind`/`capabilities`
  of the wrong JSON type MUST be tolerated (extension-manifest-013/014/015).
  A `themes`/`commands`/... entry that is a single JSON object rather than
  an array MUST be accepted as a one-element array (extension-manifest-010).
  A configuration property that spells nullability as `[X, null]` instead
  of `[X, "null"]` MUST collapse identically to the string form
  (extension-manifest-022). Deeply nested/recursive generic-JSON input has
  no depth guard anywhere in this component — a pathologically deep
  manifest MAY recurse as far as the JSON itself nests, bounded only by the
  underlying decoder's own container-decoding limits, not by any check this
  component adds.
- **Concurrent access**: a manifest, its contributions value, and every
  nested type are immutable, side-effect-free values; decoding a manifest
  allocates its own encode/decode pair per call and touches no shared
  mutable state, so concurrent, independent decode calls on independent
  inputs MUST NOT require external synchronization.
- **Error states**: A malformed `name`, `version`, `engines.vscode`, or
  `contributes` shape MUST sink the entire decode
  (**top-level-identity-required**, **contributes-strict**); every other
  malformed field MUST instead resolve to its type's absence value
  (absent/empty list/empty dictionary) — with a recorded decoding failure
  for most of them, but silently and with no decoding failure at all for a
  command entry's `icon`, every configuration property field, and a view
  container's `icon`/`when` (see Design Decisions).
- **Offline/disconnected state**: Not applicable — this component performs
  no network or file I/O of its own; decoding a manifest operates purely on
  the input its caller already obtained, with no network, file-system, or
  process call anywhere in this component.

