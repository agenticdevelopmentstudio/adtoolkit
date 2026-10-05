
| ID | Requirements | Input / Precondition | Action | Expected |
|----|-------------|----------------------|--------|----------|
| env-filter-001 | signature, default-all-selected, all-list | Empty storage | Create the state; read the initial result | `envs` equals `{production, staging, testing}`; `all` is `["production","staging","testing"]`; `toggle` is a function |
| env-filter-002 | deferred-hydration, array-hydration, storage-key | `"adh-env-filter"` = `["production"]` | Create the state; capture the initial result; let hydration run | Initial `envs` = all three; after hydration `envs` = `{production}` |
| env-filter-003 | absent-value-keeps-default | `"adh-env-filter"` = `""` (empty string) | Create the state; let hydration run | `envs` stays all three; the value is never parsed |
| env-filter-004 | invalid-entries-dropped, duplicates-collapse | `"adh-env-filter"` = `["staging", 7, "prod", "staging", null]` | Create the state; let hydration run | `envs` = `{staging}` (size 1) |
| env-filter-005 | filtered-to-empty | `"adh-env-filter"` = `[]` | Create the state; let hydration run | `envs` is an empty set |
| env-filter-006 | filtered-to-empty | `"adh-env-filter"` = `["qa","dev"]` | Create the state; let hydration run | `envs` is an empty set (not the default) |
| env-filter-007 | non-array-keeps-default | `"adh-env-filter"` = `{"production":true}` | Create the state; let hydration run | `envs` stays all three |
| env-filter-008 | read-failure-keeps-default | `"adh-env-filter"` = `{not json` | Create the state; let hydration run | No exception escapes; `envs` stays all three |
| env-filter-009 | read-failure-keeps-default | The storage read throws a security error | Create the state; let hydration run | No exception escapes; `envs` stays all three |
| env-filter-010 | toggle-flip, toggle-persist, envs-immutability | Default state (all three) | Call `toggle("staging")` | `envs` = `{production, testing}` and is a different set instance; storage holds `["production","testing"]` |
| env-filter-011 | toggle-flip, toggle-order, toggle-persist | State after env-filter-010 | Call `toggle("staging")` | `envs` = `{production, testing, staging}`; storage holds `["production","testing","staging"]` |
| env-filter-012 | toggle-may-empty | `envs` = `{production}` | Call `toggle("production")` | `envs` is empty; storage holds `[]` |
| env-filter-013 | toggle-functional-update | Default state | Call `toggle("production")` and `toggle("testing")` together | `envs` = `{staging}`; storage holds `["staging"]` |
| env-filter-014 | write-failure-ignored | The storage write throws a quota-exceeded error | Call `toggle("testing")` | No exception escapes; `envs` = `{production, staging}` |
| env-filter-015 | toggle-unvalidated | Default state | Call `toggle("qa")`; then recreate the state and let hydration run | Before recreation `envs` has 4 members including `qa`, storage holds `["production","staging","testing","qa"]`; after recreation `envs` = all three |
| env-filter-016 | toggle-identity, all-list | Any state | Call `toggle` to force a state update; compare the returned `toggle` and `all` with the previous result's | Both are reference-equal to the previous values |
| env-filter-017 | storage-key | Storage holds `"adh-env-filter"` = `["production"]` | Run a routine that purges retired storage keys | The key survives unchanged; a companion test asserts this ("leaves keys the app still uses alone") |
| env-filter-018 | client-only | Environment Filter is loaded in a server-only rendering context | Render it | It is unavailable there: the module is marked for client execution only |

