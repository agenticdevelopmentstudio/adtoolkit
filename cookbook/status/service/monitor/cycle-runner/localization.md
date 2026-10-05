
This file's only literal string is the hardcoded English `console.log` message it builds for a retention prune (maintenance-prune-logged-on-deletion). It routes through no localization mechanism, and unlike the Slack/Discord-rendered lines in `alerts.ts` (see the [Status Server Monitor Alerts](adtoolkit://cookbook/status/service/monitor/alerts) recipe), this string's only audience is an operator reading container stdout, never an end user or a webhook receiver.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `[maintenance] pruned <deleted> retention rows` | `console.log` after a full sync's `runMaintenance` call, when `deleted > 0` |
| n/a | ` — more next cycle` | Suffix appended to the line above when `runMaintenance`'s `done` flag is `false` |

