
Vectors 001–006 are traced to the module's own test suite; 007–010 to a parity test suite; the rest to the operations' own bodies. `H` = 3,600,000 ms (one hour). A "deploy row" below is an activity row with kind `"deploy"`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overview-001 | real-env-vercel-preview, real-env-dto-delegates | The record form of the predicate on a deployment record with platform `"vercel"`, environment absent, status `"failed"` | `false` |
| overview-002 | real-env-vercel-target, real-env-dto-delegates | The record form of the predicate on a deployment record with platform `"vercel"`, environment `"production"` | `true` |
| overview-003 | real-env-other-platforms | The record form of the predicate on a deployment record with platform `"cloudflare-pages"`, environment absent | `true` |
| overview-004 | real-env-row-signature, real-env-vercel-preview, real-env-vercel-target, real-env-other-platforms | The platform/environment form of the predicate on `("vercel", absent)`, `("vercel", "")`, `("vercel", "production")`, `("railway", absent)`, `("cloudflare-pages", absent)` | `false`, `false`, `true`, `true`, `true` |
| overview-005 | window-hours, window-hours-label, window-days | The activity-window-caption operation on spans of `24H`, `7×24H` and `47H`, each from time `0` | `"24h"`; `"7d"`; `"47h"` |
| overview-006 | window-min-one-hour | The activity-window-caption operation on a span of `60000` ms, from time `0` | `"1h"` |
| overview-007 | indicator-map-exhaustive, indicator-map-values | Sorted keys of the wire-indicator translation map; its values | `["degraded","operational","outage"]`; `"warn"`, `"ok"`, `"down"` |
| overview-008 | indicator-empty-ok, indicator-server-parity | The problems-to-indicator operation on an empty list | sign state `"ok"`, count `0` |
| overview-009 | indicator-otherwise-warn, indicator-count | The operation on problems with severities `minor, minor`; then `major, minor` | sign state `"warn"`, count `2`, both times |
| overview-010 | indicator-critical-down, indicator-count | The operation on problems with severities `minor, major, critical` | sign state `"down"`, count `3` |
| overview-011 | headline-ok | The headline operation with sign state `"ok"` and count `5` | `"ALL SYSTEMS OPERATIONAL"` |
| overview-012 | headline-warn-singular, headline-warn-plural | The headline operation with sign state `"warn"` and count `1`; then count `3` | `"1 SERVICE NEEDS ATTENTION"`; `"3 SERVICES NEED ATTENTION"` |
| overview-013 | headline-down-singular, headline-down-plural | The headline operation with sign state `"down"` and count `1`; then count `4` | `"1 PROBLEM"`; `"4 PROBLEMS"` |
| overview-014 | counts-builds, counts-deploys, counts-failures | The deploy-counts operation over deploy rows at the window-start time or later: step `"build"`/tone `"good"`; step `"build"`/tone `"bad"`; step `"deploy"`/tone `"good"` | build count `2`, deploy count `1`, failure count `1` |
| overview-015 | counts-deploy-kind-only, counts-window-cutoff | The operation with a probe-kind row (tone `"bad"`), a deploy row one millisecond before the window-start time, and a deploy build row exactly at the window-start time | build count `1`, deploy count `0`, failure count `0` |
| overview-016 | counts-null-step, counts-failures | The operation with one deploy row, no step, tone `"bad"`, inside the window | build count `0`, deploy count `0`, failure count `1` |
| overview-017 | window-days, window-hours-label | The caption operation on spans of `48H`, `72H` and `24H`, each from time `0` | `"2d"`; `"3d"`; `"24h"` (stays hours) |
| overview-018 | window-min-one-hour | The caption operation from time `10H` to time `0` (a negative span) | `"1h"` |
| overview-019 | real-env-case-sensitive | The platform/environment form of the predicate on `("Vercel", absent)` | `true` |

