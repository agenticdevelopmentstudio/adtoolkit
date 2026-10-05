
- **Data collected**: `auth-store.ts` persists an email, optional password
  hash, optional GitHub id, and role per user. `token-store.ts` persists
  only a `tokenHash` and a display-only `prefix` per API token — never the
  raw bearer. `device-store.ts` persists only `deviceCodeHash`/
  `userCodeHash` per grant, with `tokenRaw` as the one documented,
  time-boxed exception: held in the row only between `approve` and the
  single successful `consumeApproved` call, which clears it as part of
  the same atomic statement. `telemetry-store.ts` persists polled,
  aggregate third-party data (GlitchTip issue titles/culprits/counts,
  analytics pageview/visitor counts) — not raw end-user request data.
- **Storage**: every store in this layer persists through the single `Db`
  handle it is constructed with; none opens a second connection or writes
  to a second store.
- **Transmission**: none of these 14 files performs a network call —
  `validateApiToken`, `resolveSession`, and every other lookup compare
  only locally-computed hashes against stored hashes; the raw secret a
  caller presents is hashed in-process and never re-transmitted or logged
  by this layer.
- **Retention**: `pruneOlderThanDays` (deploy-store.ts), the retention
  prune inside `runMaintenance` (maintenance-store.ts), and `purgeExpired`
  (device-store.ts) are this layer's own retention mechanisms;
  `deleteGroup`/`deleteSite`/`deleteEndpoint`'s history/issue cascades
  (config-store.ts) are retention triggered by an explicit administrative
  delete rather than age. No other file in this layer deletes a row on a
  schedule of its own.

