
This file's only literal strings are hardcoded English `console.log`/`console.error` messages (operator-facing, container stdout) and the two alert `detail` strings assembled in `retire-unclaimed-monitors`' `why` callback (`its <platform> project "<name>" no longer exists`, `no deploy project serves <host> any more`) — all routed through no localization mechanism, all consumed by an operator or by `notifyIssueAlert`'s own Slack/Discord-rendering (external, documented in the [Status Server Monitor Alerts](adtoolkit://cookbook/status/service/monitor/alerts) recipe), never by an end user.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `[sync] removed monitor <name> (<url>) — <reason>` | `console.log` after a successful `retireEndpoint` call |
| n/a | `[sync] failed to remove monitor <slug> (<reason>): <err>` | `console.error` after a rejected `retireEndpoint` call |
| n/a | `[sync] not removing monitors — <reason>` | `console.log`, once per string in `endpointsClaimedByNothing`'s `withheld` list |
| n/a | `[sync] <label> is rate-limited — skipping until <ISO timestamp>` | `console.error` inside `guard`, when `rateLimitedUntil` returns a cooldown |
| n/a | `[sync] <label> poll exceeded 20000ms — treating as unreachable` | `console.error` inside `guard`, on the timeout branch |
| n/a | `[sync] <label> poll threw — treating as unreachable: <err>` | `console.error` inside `guard`, on the caught-throw branch |
| n/a | `[sync] all deploy fetchers failed — skipping prune` | `console.error` when every one of `vc.ok/cf.ok/ry.ok/prod.ok/cr.ok` is `false` |
| n/a | `[sync] deploy-project enumeration failed — skipping monitor removal: <err>` | `console.error` when `enumerateDeployProjects` rejects |
| n/a | `its <platform> project "<name>" no longer exists` | `retired` alert `detail` / removal-log `reason`, for a wired-and-gone monitor |
| n/a | `no deploy project serves <host> any more` | `retired` alert `detail` / removal-log `reason`, for an unwired-and-unclaimed monitor |

