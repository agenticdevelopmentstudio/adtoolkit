
Every string the function returns is hardcoded English, with no localization layer. Pluralization is a binary count-equals-1 test that appends `s` (or, for platforms, swaps in "platforms"). The `down`, `degraded` and unmapped phrases are never pluralized. The separator is a literal `" · "`.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `{healthy}/{total} endpoints healthy · no failed builds` | Clear board, every endpoint healthy |
| (none; literal) | `{total} endpoints monitored · no failed builds` | Clear board, not every endpoint healthy |
| (none; literal) | `{n} down` | Breakdown, `down` rows |
| (none; literal) | `{n} degraded` | Breakdown, `degraded` rows |
| (none; literal) | `{n} failed build` / `{n} failed builds` | Breakdown, `build failed` rows |
| (none; literal) | `{n} failed deploy` / `{n} failed deploys` | Breakdown, `deploy failed` rows |
| (none; literal) | `{n} stale deploy` / `{n} stale deploys` | Breakdown, `deployment failed` rows |
| (none; literal) | `{n} stuck build` / `{n} stuck builds` | Breakdown, `building` rows |
| (none; literal) | `{n} platform unreachable` / `{n} platforms unreachable` | Breakdown, `platform unreachable` rows |
| (none; literal) | `{n} {statusWord}` | Breakdown, any unmapped status word (the word comes from the row) |
| (none; literal) | ` · ` | Separator between phrases |

