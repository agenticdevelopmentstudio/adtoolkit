
This file's `staleDetail` function produces hardcoded, unlocalized English strings that ARE end-user-facing — they populate the `detail` field of every stale `VercelProdState`, which the caller surfaces on the status board for whoever is monitoring deploys. None of the four base reason strings, nor the `` · live build <age> old `` suffix (built from `timeAgo`'s hardcoded `"just now"`/`"<n>m"`/`"<n>h"`/`"<n>d"` outputs, `./time-ago`, external), route through any localization mechanism.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — no key) | `production not updated to the latest build` | `staleDetail` base reason when `errored` is false |
| (none — no key) | `live production build errored` | `staleDetail` base reason when `errored` is true and `behind` is false |
| (none — no key) | `live production build errored; newer build not promoted` | `staleDetail` base reason when both `errored` and `behind` are true |
| (none — no key) | `<reason> · live build <age> old` | `staleDetail`'s age-qualified form, appended only when `liveCreated` resolves to a valid, non-zero date |

Every `console.error`/`console.log` diagnostic line elsewhere in this file (the truncation reasons, the per-deploy `createdAt` warning, the team-lookup failure, the blind-backfill notice) is operator-facing server-log text, not shown to an end user of the monitored product, and is documented under Logging rather than here.

