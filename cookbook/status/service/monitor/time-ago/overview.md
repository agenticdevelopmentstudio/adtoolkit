
`time-ago.ts` (`packages/web/packages/status-server/src/monitor/time-ago.ts`) is the
status server's single pure function for turning one absolute timestamp into a compact,
human-readable elapsed-time label. It exports one function, `timeAgo(iso, nowMs)`, whose
own doc comment states its purpose directly: "Format elapsed time as a compact string.
nowMs is passed in for testability." It has two callers in the given source tree:
`integrations.ts`'s freshness check for the last stored health-check timestamp
(`ageLabel`, folded into a `"stale — last {ageLabel} ago"` / `"last check {ageLabel} ago"`
detail string), and `fetch-vercel-projects.ts`'s `staleDetail`, which folds the age of a
stale production project's last live build into a `"... live build {age} old"` message.
Both callers derive `iso` from a `Date` they already checked is valid or non-null before
calling `timeAgo`, and both pass a `Date.now()`-derived value for `nowMs`.

