
- **Null/empty input**: A slug of `""` after lowercasing — the slug pattern
  requires at least one leading/trailing alphanumeric character, so both
  the field validator's pattern check and the save action's own validation
  reject it before any network call. Resolving the workspace default
  ecosystem id with an empty result list MUST resolve to nothing, never an
  undefined/absent-marker value or a thrown error
  (hub-domain-ecosystems-031); resolving an ecosystem id for a slug then
  falls back to the raw scan, and MUST resolve to nothing only when that
  scan is also empty (hub-domain-ecosystems-051).
- **Boundary/malformed values**: A slug at exactly 64 characters — MUST be
  accepted; at 65 — MUST be rejected with the fixed message
  (hub-domain-ecosystems-015). A non-rdid identifier passed to create/update
  (no `.` at all) — the client MUST pass its whole value through as `slug`
  unmodified via the leaf-extraction fallback, deliberately letting the
  SERVER reject the malformed address rather than fabricating a
  different-looking error client-side.
- **Concurrent access**: Two closely-timed create-form saves for the same
  slug — the client-side existence probe is a courtesy check only; a probe
  that returns "not taken" right before a competing create lands is a real
  race the backend's own unique constraint resolves via a conflict
  response, which both reference implementations map to a friendly "already
  exists" message (create-form-conflict-mapping, create-conflict-mapping)
  — the probe narrows the window, it does not close it.
- **Error states**: Every data-access call that can fail surfaces a typed
  error to its caller — a domain error on one reference implementation
  (never a raw, untyped error reaching a topic or the root listing), an
  error carrying a numeric status on the other. A not-found result is the
  one case multiple call sites treat as a structural, non-error outcome (an
  empty result on the rail; nothing from the get-by-id call) rather than a
  failure to surface.
- **Manageability / authorization**: An ecosystem whose `canManage` is
  explicitly `false` — the rail MUST refuse to resolve ANY topic under it,
  including child-ecosystems and settings, returning only the
  not-manageable notice (child-manageability-gate-first). The other
  reference implementation carries the equivalent `canManage` value through
  its row mapping and workspace-default resolution, but enforcing it
  against a pane is each host's own responsibility — this component only
  reports the flag.
- **Identifier drift (handle vs. derived address)**: A row whose stored
  id/identifier (handle) and slug column have diverged — because something
  renamed the handle without moving the slug (the deprecated generic
  identifier-rename path, or an old ancestor-cascade bug) — derives to a
  DIFFERENT address than its own handle claims. The update call heals this
  specific case: sending the handle's own current value as the new
  identifier is a genuine slug change (matching the stale handle) that a
  naive diff-against-id would have silently skipped
  (update-slug-sent-on-presence, hub-domain-ecosystems-026).
- **Feature removal already done**: a removal whose delete request reports
  not-found (a double-click, a stale list, a second tab racing the same
  removal) MUST resolve as success, and inside a batch apply it MUST count
  as a successful removal (hub-domain-ecosystems-037, -041).
- **Feature batch partial failure**: A batch apply whose adds succeed but
  some removals fail with a non-not-found error MUST keep the adds, still
  attempt every other removal, reject naming only the failed keys, and
  invalidate the provisioned list (hub-domain-ecosystems-040). A failed add
  MUST reject before any removal is sent (hub-domain-ecosystems-047);
  whether the backend's batch transaction rolls back whole is the
  backend's contract, which this client relies on and does not verify.
- **Empty feature change**: A batch apply with nothing to add MUST send no
  add request; with nothing to remove it MUST send no removal request and
  resolve. With both empty it sends nothing and still invalidates the
  provisioned list. Provisioning has no such guard: provisioning an empty
  batch MUST still send an add request carrying an empty batch.
- **Already-active or stale feature keys**: provisioning a key that is
  already active is a backend no-op, not a conflict — the client sends it
  unchanged and surfaces whatever the backend answers; a provisioning-state
  row is the picker's concern to show as already taken.
- **Coming-soon feature submitted**: provisioning sends a coming-soon key
  unchanged if a caller supplies one; the backend refuses it and the
  rejection surfaces unchanged to the caller — this client performs no
  client-side refusal.
- **Feature hooks with no ecosystem id**: the provisioned-features query
  MUST NOT fetch while the id is nothing/undefined/empty; the mutations do
  not guard it (see the features-mutation-null-id-unguarded requirement).
- **Concurrent feature changes**: the removals inside one batch apply run
  in parallel; they touch distinct keys, so their completion order does not
  affect the result, and the list is re-read once on settle. Two sessions
  changing the same ecosystem are reconciled only by the post-mutation
  invalidation re-reading the server's list.

