
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Ready state, ready substate, target (inputs to the Vercel phase mapper) | string, optional string, optional string | none — caller-supplied per call | The Vercel deployment fields the caller (external) already fetched or received via webhook. |
| Status (input to the Railway phase mapper) | string | none — caller-supplied per call | The Railway deployment status field the caller already fetched or received via webhook. |
| State, suspended flag (inputs to the Crunchy Bridge phase mapper) | string, boolean | none — caller-supplied per call | The Crunchy Bridge cluster's documented state string and its compute-is-off flag, as fetched by the caller (external). |
| Prefix (input to the in-flight and per-column overwritable-predicate builders) | one of an empty prefix or an incoming-row alias prefix | empty prefix | Selects whether the built predicate reads the stored row (empty prefix) or an upsert's incoming row (the incoming-row alias). |
| Column (input to the per-column overwritable-predicate and webhook-guard predicate builders) | one of the two lifecycle column names | none — required | Selects which single lifecycle column the built predicate evaluates; the type itself is the only validation — no other value is accepted at construction time. |
| Target value (input to the build-phase and deploy-phase collapse builders) | a build phase / a deploy phase | none — required | The terminal value the built conditional expression collapses an in-flight column to. |

