
- **plan-struct-shape**: the plan value MUST declare exactly three stored
  fields — `keep` (a list of tab records), `add` (a list of checkouts),
  and `drop` (a list of ids) — with no default values, so every plan value
  MUST be built from all three.
- **plan-is-unchanged**: the plan's `isUnchanged` MUST return `true`
  exactly when both `add` and `drop` are empty, regardless of how many
  records `keep` holds.
- **plan-resolves-project-directory**: building a plan MUST resolve the
  project directory by following symlinks once, before evaluating any
  stored record or any checkout, and MUST use that resolved value for
  every later comparison.
- **plan-checkout-directory-set**: building a plan MUST build the set of
  every checkout's directory before evaluating any stored record, so a
  record's fate depends on the whole checkout list, not on the order the
  stored records were given.
- **plan-record-directory-resolution**: for each stored record, building a
  plan MUST resolve that record's working directory (falling back to the
  project directory when the record has none) by following symlinks, to
  obtain the directory used for every later comparison for that record.
- **plan-gone-determination**: building a plan MUST treat a record's
  resolved directory as gone only when that directory is neither a member
  of the checkout-directory set nor reported present by the existence
  check.
- **plan-drop-requires-mounted-volume**: building a plan MUST add a
  record's id to `drop` only when the record's directory is gone and the
  mount check for that directory also returns `true`; a record whose
  directory is gone but whose volume is not mounted MUST NOT be added to
  `drop`.
- **plan-keep-default**: building a plan MUST add a record to `keep`, and
  MUST mark its resolved directory as covered, for every stored record
  that is not added to `drop` — whether because its directory is not gone,
  or because it is gone but its volume is not mounted.
- **plan-add-derivation**: building a plan MUST populate `add` with every
  checkout whose directory is not covered after every stored record has
  been processed.
- **plan-exists-on-disk-default**: building a plan MUST default the
  existence check to a function that reports whether a path exists on the
  local filesystem, when the caller supplies no existence check.
- **plan-volume-is-mounted-default**: building a plan MUST default the
  mount check to the mount-lookup function described in
  **volume-is-mounted-contract**, evaluated against the already-resolved
  project directory, when the caller supplies no mount-check argument.
- **volume-is-mounted-contract**: the mount-lookup function MUST return
  `false` when the deepest existing ancestor of the candidate directory is
  exactly the removable-volumes mount point, and otherwise MUST return
  whether that ancestor's volume matches the volume of the deepest
  existing ancestor of the project directory.
- **deepest-existing-ancestor-walk**: the deepest-existing-ancestor walk
  MUST resolve symlinks in the given directory, MUST then repeatedly move
  up one path component until the candidate is reported present on the
  local filesystem, and MUST return the candidate unchanged, even if it
  does not exist, once moving up stops changing it — the filesystem root.
- **volume-url-lookup-failure**: the volume lookup MUST return no result,
  rather than throwing or crashing, whenever the underlying volume-identity
  query fails for the given directory.
- **arrangement-selection**: selecting a layout MUST return the layout
  root of the tab whose id equals the active-tab id when such a tab
  exists, and otherwise MUST return the layout root of the first tab.
- **arrangement-empty-tabs**: selecting a layout MUST return no result
  when the tab list is empty, since both the id lookup and the
  first-tab fallback are empty for an empty list.
- **make-records-shared-group**: building tab records for a checkout MUST
  generate exactly one fresh group id per call and MUST assign that same
  group id to every tab record it returns.
- **make-records-one-per-edge**: building tab records for a checkout MUST
  return exactly one tab record for every enabled edge, in the same order,
  with each returned record's `edge` set to that edge.
- **make-records-shared-fields**: every tab record this operation returns
  MUST set `title` to the checkout's display name and `workingDirectory`
  to the checkout's directory.
- **make-records-fresh-blueprint-per-edge**: building tab records for a
  checkout MUST invoke the layout-blueprint factory once for every enabled
  edge and MUST NOT reuse one layout value across more than one returned
  record's `root`, so that every returned record's `root` carries a
  distinct layout-node id (verified by
  `testMakeRecordsGivesEachEdgeMemberADistinctRootNodeID`).
- **reconciler-no-mutation-of-inputs**: building a plan, selecting a
  layout, and building tab records MUST NOT mutate the stored records, the
  checkouts, or the tab list passed to them; each builds its result from
  local values and returns a new value.
- **reconciler-synchronous-non-throwing**: building a plan, the
  mount-lookup function, selecting a layout, and building tab records MUST
  each be synchronous and non-throwing.
- **duplicate-checkout-directory-handling**: Unique checkout directories
  are a caller precondition. Building a plan derives `add` by filtering
  the checkouts against the covered-directory set in one pass that does
  not update that set as it goes, so it does not deduplicate the checkouts
  itself; its input comes from resolving the current checkouts over a
  fresh worktree listing, and git registers each worktree at a distinct
  path. A caller that passes two checkouts sharing one uncovered directory
  gets both in `add`.
- **volume-lookup-failure-handling**: the volume lookup collapses every failure of the underlying volume-identity query (a thrown error and a successful call with no volume) into the same no-result outcome, so when both sides' lookups fail the mount-lookup function's equality check evaluates to true and reports the directory mounted; building a plan then retains or drops a record on a mount status that was never established (see Design Decisions).

