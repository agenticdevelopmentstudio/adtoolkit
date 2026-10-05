
Vectors 001–005 come from `config-status.test.ts`; its fixture defaults to `kind: "frontend"`, `platform: null`, `deployProject: null`, `ignoreProjectWarning: false`. The rest follow from the opt-out fold and the engine's own status classifier.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| config-status-001 | opt-out-paused, status-unwired-opted-out, unconfigured-derived | The unconfigured predicate on the fixture with `isActive: false` | `false` |
| config-status-002 | opt-out-strict-false, status-unwired-not-opted-out, is-active-optional | The unconfigured predicate on the fixture with `isActive` unset, then with `isActive: true` | `true` both times |
| config-status-003 | status-folds-before-classify, status-unwired-opted-out | The status operation on the fixture with `isActive: false` | `"ignored"` |
| config-status-004 | status-paused-wired-stays-configured, status-wired | The status operation on the fixture with `platform: "vercel"`, `deployProject: "p"`, `isActive: false` | `"configured"` |
| config-status-005 | unconfigured-uses-wrapper, unconfigured-derived | For each of: fixture with `isActive: false`; with `isActive: true`; wired with `isActive: false` — compare the unconfigured predicate's result with the status operation returning `"unconfigured"` | Equal for all three |
| config-status-006 | opt-out-ignore-flag | The opt-out fold given `{ ignoreProjectWarning: true, isActive: true }` | `true` |
| config-status-007 | opt-out-default, opt-out-strict-true | The opt-out fold given `{}` and given `{ ignoreProjectWarning: false, isActive: true }` | `false` both times |
| config-status-008 | status-infra-kind | The status operation given `{ kind: "health", platform: null, deployProject: null, isActive: true }` | `"configured"` |
| config-status-009 | status-unwired-opted-out, opt-out-ignore-flag | The status operation on the fixture with `ignoreProjectWarning: true` and `isActive` unset | `"ignored"` |
| config-status-010 | status-empty-string-unwired | The status operation given `{ kind: "frontend", platform: "vercel", deployProject: "", isActive: true }` | `"unconfigured"` |
| config-status-011 | status-no-mutation | Run the status operation on an object with `ignoreProjectWarning: false`, `isActive: false`; then read the object's `ignoreProjectWarning` | Still `false` |
| config-status-012 | pure-synchronous, no-errors | Call each export twice with the same fixture | Same return value both times, returned synchronously, no exception |
| config-status-013 | endpoint-like-shape | An object carrying only `kind`, `platform`, `deployProject` used where the endpoint-like shape is expected | Satisfies the shape |
| config-status-014 | opt-out-minimal-input | The opt-out fold given `{ isActive: false }` with no other fields | Returns `true` |
| config-status-015 | server-twin | Run the same `{ ignoreProjectWarning, isActive }` combinations through this module's opt-out fold and the backend's own fold | Identical results for every combination |
| config-status-016 | status-delegates-to-engine | For any endpoint, compare this module's status operation with the shared engine's own classifier given the same endpoint with `ignoreProjectWarning` replaced by the opt-out fold's result | Equal |
| config-status-017 | no-validation | Pass an endpoint with an unknown `kind` such as `"frontend"` or `"xyz"` and no wiring | Treated as deploy-backed, `"unconfigured"`, no error |

