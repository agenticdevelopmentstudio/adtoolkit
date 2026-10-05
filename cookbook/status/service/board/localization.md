
| String | Source | Notes |
|--------|--------|-------|
| `"stuck ${status} · ${minutes}m"` | `derive-problems.ts`'s `stuckDetail` | Hardcoded English; the interpolated status word itself also comes from an English vocabulary map. |
| `"${label} API unreachable — ${cost}"` | `derive-problems.ts`'s `platformProblems` | `cost` defaults to `"deploys for this platform can't be monitored"`, overridden per-provider in `PLATFORM_UNREACHABLE_COST`. |
| `"HTTP ${statusCode}"` / `"no response"` / `"DNS did not resolve"` | `derive-problems.ts`'s `endpointProblems` | Hardcoded English detail strings for an endpoint Problem. |
| `"${count} unresolved error${count === 1 ? "" : "s"} · ${title}"` | `derive-problems.ts`'s `errorProblems` | English pluralization is hand-rolled (a ternary), not run through an i18n pluralizer. |
| `"${count}× ${title}"` | `derive-problems.ts`'s `errorProblems` (the `errorText` block) | Uses the literal `×` character, not a localized multiplication sign. |
| Build/deploy/issue verbs (`"queued"`, `"building"`, `"built"`, `"build failed"`, `"canceled"`, `"outcome unknown"`, `"deploying"`, `"deployed"`, `"deploy failed"`, and every `ISSUE_VERB` entry: `"down"`, `"degraded"`, `"deploy failed"`, `"deploy stuck"`, `"deployment failed"`, `"platform unreachable"`, `"app errors"`) | `derive-activity.ts`'s `BUILD_VERB`/`DEPLOY_VERB`/`ISSUE_VERB` maps | The entire Activity-row vocabulary is hardcoded English, mirrored byte-for-byte by a client-side copy per the source's own comment — a hardcoded string is a fact to record here, not a gap to excuse. |

