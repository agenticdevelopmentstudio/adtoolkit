
### Signature and purity

- **sublabel-signature**: The sublabel-building function MUST take a state (one of the indicator states), `healthyCount` (number), `servicesLength` (number) and `problems` (a list of rows), and MUST return a string.
- **sublabel-pure**: The sublabel-building function MUST have no side effects. It MUST NOT mutate `problems` or any row, and MUST NOT perform I/O, log, or read global state.
- **sublabel-synchronous**: The sublabel-building function MUST return its result synchronously, so calls cannot interleave.
- **sublabel-no-throw**: For inputs that match the declared types, the sublabel-building function MUST NOT throw. No path in the function raises an error.

### Clear board (state is `"ok"`)

- **ok-ignores-problems**: When `state` is `"ok"`, the result MUST NOT depend on `problems`, even if the list is non-empty.
- **ok-all-healthy**: When `state` is `"ok"` and `healthyCount` exactly equals `servicesLength`, the function MUST return `<healthyCount>/<servicesLength> endpoints healthy · no failed builds`, with the actual numbers substituted for `<healthyCount>` and `<servicesLength>`.
- **ok-not-all-healthy**: When `state` is `"ok"` and `healthyCount` does not exactly equal `servicesLength`, the function MUST return `<servicesLength> endpoints monitored · no failed builds` and MUST NOT print a fraction. The source comment explains why: while the board is operational, a non-healthy endpoint is a transient blip or an unprobed endpoint, and "4/5 healthy" would contradict "ALL SYSTEMS OPERATIONAL".
- **ok-strict-equality**: The all-healthy test MUST be exact numeric equality. Any other relationship, including `healthyCount` greater than `servicesLength`, MUST take the "monitored" branch.

### Problem breakdown (state is `"warn"` or `"down"`)

- **breakdown-group-by-status-word**: For any `state` other than `"ok"`, the function MUST count `problems` grouped by exact `statusWord`. Matching is case-sensitive and whitespace-sensitive.
- **breakdown-ignores-counts-args**: For any `state` other than `"ok"`, the result MUST NOT depend on `healthyCount` or `servicesLength`.
- **breakdown-phrase-down**: A group of `n` rows with status word `"down"` MUST render as `<n> down`. This phrase has no plural form.
- **breakdown-phrase-degraded**: A group of `n` rows with status word `"degraded"` MUST render as `<n> degraded`. This phrase has no plural form.
- **breakdown-phrase-build-failed**: A group with status word `"build failed"` MUST render as `"1 failed build"` when the count is 1, and as `<n> failed builds` for every other count.
- **breakdown-phrase-deploy-failed**: A group with status word `"deploy failed"` MUST render as `"1 failed deploy"` when the count is 1, and as `<n> failed deploys` otherwise.
- **breakdown-phrase-deployment-failed**: A group with status word `"deployment failed"` MUST render as `"1 stale deploy"` when the count is 1, and as `<n> stale deploys` otherwise. The status word is relabelled as "stale", not "failed".
- **breakdown-phrase-building**: A group with status word `"building"` MUST render as `"1 stuck build"` when the count is 1, and as `<n> stuck builds` otherwise. The source comment gives the reason: "a building row only reaches Problems when stuck".
- **breakdown-phrase-platform-unreachable**: A group with status word `"platform unreachable"` MUST render as `"1 platform unreachable"` when the count is 1, and as `<n> platforms unreachable` otherwise.
- **breakdown-mapped-order**: Mapped phrases MUST appear in the fixed table order `down`, `degraded`, `build failed`, `deploy failed`, `deployment failed`, `building`, `platform unreachable`, whatever order the rows arrive in.
- **breakdown-unmapped-verbatim**: A status word with no entry in the sublabel-phrase table MUST render as `<n> <statusWord>`, using the word verbatim with no pluralization.
- **breakdown-unmapped-after-mapped**: Unmapped groups MUST appear after all mapped phrases, in the order each word first occurs in `problems`.
- **breakdown-no-zero-groups**: Only status words that occur at least once in `problems` MUST produce a phrase. The function MUST NOT emit a zero-count phrase.
- **breakdown-separator**: Phrases MUST be joined with `" · "` (space, U+00B7 MIDDLE DOT, space), with no leading or trailing separator.
- **breakdown-sums-to-problem-count**: The counts in the phrases MUST add up to the length of `problems`, so every problem row is counted exactly once.
- **breakdown-empty-problems**: For any `state` other than `"ok"` with an empty `problems`, the function MUST return the empty string `""`.

### Caller preconditions

- **caller-pairs-state-and-problems**: The function MUST trust the caller's pairing of `state` with `problems` and MUST NOT re-derive the state. The "sum to the indicator count" guarantee in the doc comment holds only when the caller passes the same problem set the indicator counted. The overview tab view pairs the indicator's state with its `problems` rows.
- **caller-counts-services**: `healthyCount` and `servicesLength` are caller-computed. The overview tab view passes the number of env-filtered services with a status of `"healthy"` and the length of that filtered list. The function does not validate them.

