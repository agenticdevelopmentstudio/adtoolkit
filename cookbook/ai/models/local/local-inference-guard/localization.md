
The guard defines no string-key or localization-table lookup; every string
it produces is a hardcoded English literal composed inline, with no key
system to reference:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no key) | `Local model <model> is warn-tier: <footprint> est.` | The verdict operation's notice-level log entry when the computed tier is warn. |
| (none — literal, no key) | `local inference exceeded its <N>s deadline; deferring` | The deadline timer's expiry path, surfaced to callers as the deferred refusal's description. |

