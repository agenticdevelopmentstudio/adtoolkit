
Every `summary`/`description` string across the 14 modules (for example `authPaths['/auth/signup'].post.summary`, or `activityPaths['/activity'].get.description`) is a hardcoded English literal aimed at a developer reading the generated API documentation; none of these modules reads a string catalog, an i18n bundle, or an `Accept-Language` header, and the assembled document carries no locale dimension at all. Per this recipe's authoring rules, a hardcoded developer-facing string is a fact worth recording, not a gap to excuse with a blanket "Not applicable":

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — doc summary | `Create a status account (starts pending until an admin promotes it)` | `authPaths['/auth/signup'].post.summary` |
| n/a — doc description | `The cursor is the (before, beforeId) PAIR because a deployment's build and deploy rows share a timestamp...` | `activityPaths['/activity'].get.description` |
| n/a — doc summary | `Requirement B: write the board into the ledger — opens, updates and resolves rows (can alert)` | `boardPaths['/board/reconcile'].post.summary` |

