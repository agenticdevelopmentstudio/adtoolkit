
- **plan-struct-shape**: the plan result MUST carry four fields —
  `inserts`, `updates`, and `deletes`, each a list of repository records
  defaulting to empty, and `summary`, a scan-summary value defaulting to a
  freshly constructed instance.
- **exact-path-match-lookup**: the plan operation MUST build a lookup keyed
  by every existing record's `path` before considering any scanned
  repository, so a scanned repository's fate is decided by an exact string
  match against that lookup.
- **unmatched-scan-collection**: every scanned repository whose `path` is
  not a key in that lookup MUST be added to the set of scans available to
  the later move and insert passes, in the order the scanned list was
  given.
- **exact-path-match-remote-update**: when a scanned repository's `path`
  exactly matches a known record and that record's stored `remote` differs
  from the scanned `remote`, the plan operation MUST overwrite the record's
  `remote` with the scanned value, MUST set its `lastSeen` to the current
  time, and MUST append the mutated record to `updates`; when the two
  `remote` values are equal, the plan operation MUST NOT append anything to
  `updates` for that record.
- **exact-path-match-increments-unchanged**: the plan operation MUST
  increment `summary.unchanged` by exactly one for every scanned repository
  whose path exactly matches a known record, regardless of whether that
  same record was also just appended to `updates` for a remote change — a
  record can count toward `unchanged` and appear in `updates` in the same
  call.
- **missing-rows-exclude-seen**: after the exact-path pass, the plan
  operation MUST narrow the candidates for the skip, move, and delete
  passes to existing records whose `id` was not marked seen during that
  pass.
- **unreachable-path-skipped-not-deleted**: a missing record for which the
  repository-existence check returns `true` for that record's `path` MUST
  be excluded from both the move pass and the delete pass, and the count of
  such records MUST be added to `summary.skipped` rather than
  `summary.removed`.
- **move-by-remote-priority**: for a missing record whose `remote` is
  present and non-empty, the plan operation MUST consider only unclaimed
  scanned repositories whose `remote` equals that exact string as move
  candidates before ever consulting directory-name equality.
- **move-by-remote-requires-uniqueness**: the plan operation MUST use a
  remote-based candidate as the match only when exactly one unclaimed
  scanned repository shares the missing record's `remote`; when zero or
  more than one share it, the plan operation MUST fall back to the
  directory-name comparison instead.
- **move-by-name-fallback**: the plan operation MUST match a missing record
  to an unclaimed scanned repository by directory-name equality — the
  scanned repository's leaf directory name equal to the default name
  derived from the missing record's path — only when both the missing
  record's `remote` and the candidate's `remote` are absent or the empty
  string, and only when exactly one such candidate exists.
- **unmatched-move-becomes-delete**: a missing record for which neither the
  remote pass nor the name pass yields a unique candidate MUST remain
  unresolved after the move pass and MUST end up in `deletes`.
- **move-preserves-identity-and-name**: when a missing record is matched,
  the plan operation MUST keep that record's `id` and `name` unchanged,
  MUST overwrite its `path` and `remote` with the matched scan's values,
  MUST set its `lastSeen` to the current time, MUST append it to `updates`,
  and MUST NOT also append it to `inserts`.
- **move-claims-target-path**: the plan operation MUST record a matched
  scan's `path` as claimed at the moment the match is made, so that no
  later iteration of the move pass, and no later evaluation of the insert
  pass, can match that same scanned path a second time.
- **move-precedes-insert**: the plan operation MUST resolve every possible
  move before evaluating any scanned repository for insertion, so a
  repository's destination path after a move is never also treated as a
  brand-new project.
- **insert-unique-name**: for every scanned repository left unclaimed after
  the move pass, the plan operation MUST derive its name with a
  uniqueness-escalation rule (see `unique-name-escalation`), seeding the
  taken-names set from every existing record's current `name` and adding
  each newly assigned name to that set before processing the next unclaimed
  scan in the same call, so two repositories inserted by one call MUST NOT
  receive the same name.
- **insert-fresh-fields**: each newly inserted repository record MUST take
  its `path` and `remote` from the unmatched scan and MUST set both
  `firstSeen` and `lastSeen` to the current time, leaving `id` to default
  to a freshly generated unique identifier.
- **delete-whatever-remains**: the plan operation MUST place every missing
  record that the skip pass and the move pass left unresolved into
  `deletes`, and MUST set `summary.removed` to the count of that final
  list.
- **plan-defaults**: the plan operation MUST default the current time to
  the moment of the call and MUST default the repository-existence check to
  its own built-in filesystem check when the caller supplies neither.
- **repository-exists-check**: the repository-existence check MUST return
  whether an entry named `.git` exists directly under the given path, and —
  since existence alone is the whole test — MUST NOT additionally check
  whether that entry is a directory or contains a `HEAD` file.
- **unique-name-escalation**: the naming rule MUST split a path into its
  non-separator path components and MUST try, in order, the shortest
  trailing run of one component, then two, and so on, each joined with
  `/`, returning the first such candidate that is not a member of the
  taken-names set.
- **unique-name-empty-path**: the naming rule MUST return the path
  unchanged when it has no non-separator components.
- **unique-name-exhausted-fallback**: when every candidate through the
  full path, including the full path itself, is already present in the
  taken-names set, the naming rule MUST return the path unchanged, exactly
  as it was passed in, rather than appending a disambiguating suffix of any
  kind.
- **plan-pure-and-side-effect-free**: the plan operation, the
  repository-existence check, and the naming rule MUST each be synchronous
  and non-throwing, and none MUST perform network access, read or write a
  database, or store any state of its own between calls.
- **duplicate-existing-path-handling**: the plan operation does not
  validate that the existing records hold at most one entry per `path`; it
  relies on its caller, and the registry's storage layer enforces a
  uniqueness constraint on `path`, so stored records never repeat a path. A
  caller that passes hand-built records with a repeated path gets the
  path-keyed lookup's last-wins behavior: the earlier record can never be
  matched by the exact-path pass and, if its own path still exists on disk,
  never appears in `inserts`, `updates`, or `deletes`.
- **duplicate-scanned-path-handling**: the plan operation does not validate that the scanned entries hold at most one entry per `path`; two scanned entries sharing one path (plausible with overlapping scan roots) are each processed independently through the exact-path pass and the unmatched-scan pass, so they can produce two `updates` entries carrying the same existing record's `id`, or two `inserts` for one directory (see Design Decisions).

