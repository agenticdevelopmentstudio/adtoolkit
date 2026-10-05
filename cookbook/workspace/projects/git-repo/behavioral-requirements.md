
- **git-repo-stored-shape**: The repository record MUST store exactly
  seven fields — `id`, `path`, `name`, `remote`, `firstSeen`, `lastSeen`,
  and `lastOpened` — MUST be safely usable across concurrent contexts, MUST
  expose `id` as its stable identity, and MUST support equality comparison.
- **git-repo-id-immutable**: `id` MUST be fixed at construction; nothing on
  the repository record MUST mutate it afterward.
- **git-repo-default-id-generation**: Construction MUST generate a fresh,
  distinct unique identifier for `id` when the caller supplies none.
- **git-repo-mutable-tracking-fields**: `path`, `name`, `remote`,
  `firstSeen`, `lastSeen`, and `lastOpened` MUST all be mutable, so a caller
  holding a repository record MAY reassign any of them after construction
  without constructing a new value.
- **git-repo-default-timestamps**: Construction MUST default both
  `firstSeen` and `lastSeen` to the current time evaluated at construction
  when the caller supplies no explicit value, and MUST default `remote` and
  `lastOpened` to no value.
- **git-repo-path-and-name-required**: Construction MUST NOT provide a
  default value for `path` or `name`; every call site MUST supply both
  explicitly.
- **git-repo-url-is-directory**: The repository record's directory URL
  MUST always be built as a directory URL, regardless of whether `path`
  currently exists on disk or is actually a directory, "because a
  repository's path is one" and because the resulting URL "is compared for
  equality against checkout directories built elsewhere".
- **git-repo-default-name-from-path**: Deriving a default name from a path
  MUST return that path's final path segment, and MUST NOT consult the
  filesystem to confirm that path exists or is a directory.
- **git-repo-name-seeding-convention**: Per the doc comment on `name`
  ("Seeded from the directory name, then the user's to change,"), a caller
  constructing a brand-new repository record SHOULD seed `name` from the
  path's final path segment and treat every subsequent value as the
  user's to rename; construction itself enforces nothing here and MAY be
  called with any `name` string, including one unrelated to `path`.
- **git-repo-structural-equatable**: The repository record's equality MUST
  be evaluated over every stored field, including `id`, `firstSeen`,
  `lastSeen`, and `lastOpened` — not `id` alone — so two values that name
  the "same" repository by `id` but disagree on any other field, including
  a timestamp, MUST compare unequal (memberwise comparison over every
  field).
- **git-repo-path-absoluteness**: The doc comment on `path` declares it
  "Absolute path to the working tree," a caller precondition: nothing in
  this component validates that a supplied string is non-empty or
  absolute, so a relative path, an empty string, or a path containing `~`
  is stored and used unchanged.
- **scanned-git-repo-no-identity**: The scanned repository MUST NOT declare
  an `id` or any other identity-bearing field; it MUST store only `path`
  and `remote`, both fixed at construction, and MUST support safe
  concurrent use and equality comparison but MUST NOT be identifiable by a
  stable id — per the doc comment, "a scan result has no identity yet:
  deciding whether it is a new repository, a moved one, or one already
  known is the reconciler's job".
- **scanned-git-repo-remote-required**: Constructing a scanned repository
  MUST NOT provide a default value for `remote`; every call site MUST pass
  no value explicitly when the scanned repository has no remote, unlike the
  repository record's construction, which defaults `remote` to no value.
- **scanned-git-repo-leaf-name**: The scanned repository's leaf name MUST
  return `path`'s final path segment — the same computation the repository
  record's default-name derivation performs, implemented separately on the
  scan-result type rather than shared — and MUST NOT consult the
  filesystem.
- **scan-summary-default-zero-counts**: Constructing a scan summary with no
  arguments MUST leave `added`, `moved`, `removed`, `unchanged`, and
  `skipped` at their declared default of `0`.
- **scan-summary-fields-unvalidated**: `added`, `moved`, `removed`,
  `unchanged`, and `skipped` MUST all be mutable with no invariant enforced
  by the scan summary itself; any caller holding a value MAY set any of
  the five to a negative number or to a value inconsistent with the
  others, and nothing on this type MUST detect or reject that.
- **scan-summary-found-excludes-removed**: `found` MUST return exactly
  `added + moved + unchanged + skipped`, and MUST NOT include `removed` in
  that sum — a repository the scan deleted is not counted among "every
  project in the registry once the scan has been applied".
- **scan-summary-text-headline-pluralization**: The summary text's headline
  MUST read `"<found> project"` when `found == 1` and `"<found> projects"`
  for every other value of `found`, including `0`.
- **scan-summary-text-part-selection**: The summary text MUST append
  `"<n> new"`, `"<n> moved"`, `"<n> removed"`, and `"<n> not scanned"` to
  its parts list, in that fixed order, only for whichever of `added`,
  `moved`, `removed`, and `skipped` is strictly greater than `0`;
  `unchanged` MUST NOT appear in the parts list under any circumstance,
  regardless of its value.
- **scan-summary-text-joining**: When at least one part is selected, the
  summary text MUST join the headline and the parts with `" — "` (an em
  dash between spaces) and MUST join multiple parts with `", "`; when no
  part is selected, the summary text MUST instead append the literal
  suffix `", no changes"` to the headline.
- **value-type-concurrency-safety**: The repository record, the scanned
  repository, and the scan summary MUST each be safely usable across
  concurrent contexts with no additional synchronization, on the strength
  of being composed entirely of plain value data (identifiers, strings,
  optional strings, timestamps, optional timestamps, whole numbers); none
  declares any thread- or task-based isolation of its own, and none needs
  to, because every access operates on the caller's own copy.
- **git-repo-last-opened-may-remain-nil**: `lastOpened` MAY remain unset for
  the entire lifetime of a repository record; nothing in this component
  ever sets or reads it — per the doc comment it exists so that whichever
  component opens a project window "sorts by" it, a responsibility outside
  this component.

