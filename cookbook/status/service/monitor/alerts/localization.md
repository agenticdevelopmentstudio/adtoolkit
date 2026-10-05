
None of this module's user-facing strings route through a localization mechanism; every rendered alert-line fragment and the one error-log message are hardcoded English literals interpolated by the rendering step and the flush operation's failure-handling path. Per this recipe's authoring rules, a hardcoded string is a fact to record, not a gap to excuse — and because these rendered lines are the text an on-call engineer reads in Slack or Discord, they are genuinely user-facing, not internal-only.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `🔴 opened` | Line prefix for an `opened` alert |
| n/a | `🗑 monitor removed:` | Line prefix for a `retired` alert |
| n/a | `✅ resolved:` | Line prefix for a `resolved` alert |
| n/a | `[alerts] webhook delivery failed (<n> alerts): <message>` | Logged on a caught delivery failure |

