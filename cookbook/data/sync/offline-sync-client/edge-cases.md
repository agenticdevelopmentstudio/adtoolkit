
- **Fresh-cursor initial sync — no resync.** On a cold store the cursor is nil,
  so the first pull covers every effective resource with no gap; appearances on
  a nil cursor are *not* treated as a resync (they cannot be behind a cursor
  that does not exist yet).
- **Manifest flapping bound.** A manifest that flaps a resource in and out (or
  keeps bumping its schema version) faster than a resync can settle is bounded:
  after a configured maximum of mirror resets in one cycle (3) the engine
  surfaces a manifest-instability error (a `failed` event) and backs off,
  rather than hot-looping reset + re-pull forever.
- **Conflict without `current`.** A `conflict` result carrying no `current` row
  has nothing to adopt; it is treated as a rejection — the op is quarantined
  (reason preserved), never silently dropped.
- **Unparseable server `sync_version` ⇒ terminal quarantine.** A conflict whose
  `current.sync_version` cannot yield a numeric version — a non-finite or
  out-of-range number for a 64-bit integer, OR a non-numeric string (the
  conflict `current` payload is not schema-validated to a numeric-string
  pattern on the wire) — is unadoptable: the server row can't be mirrored. The
  op is routed to the SAME terminal quarantine path as an explicit `rejected`
  (never retried under its original opId; a fixed retry must re-stage for a
  fresh one), and the rest of the push batch still completes so the loop makes
  progress. This replaces the earlier "skip adoption but resolve" behavior,
  under which a non-numeric string was handed to the apply step verbatim,
  raised before completion, and re-pushed the op forever.
- **Re-enable after disable.** A resource disabled and later re-enabled comes
  back through the appearance rule (full resync on a non-fresh cursor), not as a
  silent resumption — its rows changed while it was outside the effective set
  and are behind the single cursor stream.
- **Enrollment disable racing an in-flight push.** If enrollment for a resource
  is disabled while a push for it is outstanding, the server answers that op with
  `rejected/not_enrolled`; the client quarantines it — the same terminal
  quarantine state the local disable transition (`disappearance-quarantines-outbox`)
  would have produced. The op is never pushed under a stale enrollment.

