
No test file exercises this logic directly; these vectors are derived from the function bodies.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| project-key-001 | key-format | key function with platform `"railway"`, projectName `"api"` | `"railway\|api"` |
| project-key-002 | key-raw-platform, key-no-trimming | key function with platform `"Railway"`, projectName `" api "` | `"Railway\| api "` (case and spaces preserved) |
| project-key-003 | key-input-shape | key function with platform `"vercel"`, projectName `"web"`, plus extra fields `domain: "x.app"`, `env: "prod"` | `"vercel\|web"` |
| project-key-004 | key-format | key function with platform `""`, projectName `""` | `"\|"` |
| project-key-005 | unique-first-seen-wins, unique-identity-preserved | de-duplication function with entries A={railway,api,env:"production"}, B={railway,api,env:"staging"}, C={railway,api,env:"testing"}, in that order | `[A]` (same value as A) |
| project-key-006 | unique-order-preserved, unique-key-equality | de-duplication function with entries X={vercel,web}, Y={railway,api}, Z={vercel,web}, W={railway,db}, in that order | `[X, Y, W]` |
| project-key-007 | unique-new-array | de-duplication function with input list `[X]` | Result is a different list from the input; input still has length 1 and identical contents |
| project-key-008 | key-raw-platform, unique-key-equality | de-duplication function with entries {platform:"railway",projectName:"api"}, {platform:"Railway",projectName:"api"} | Both entries kept (keys differ by case) |
| project-key-009 | unique-generic-element | de-duplication function with an empty list | `[]` |
| project-key-010 | per-call-state | de-duplication function called twice with `[X]` | Each call returns `[X]` |
| project-key-011 | key-determinism | key function called twice with platform `"fly"`, projectName `"svc"` | Both calls return `"fly\|svc"` |
| project-key-012 | pure-functions, no-errors-raised | Any well-typed input to either function | Returns a value without throwing; no network, storage or console activity observed |
| project-key-013 | key-single-source | The review view checks project P (adds its key to the ignore collection); the provider filters pending entries by testing membership of each entry's key in the ignore collection | Every per-environment entry of P matches the filter |
| project-key-014 | unique-production-representative | de-duplication function with entries S={railway,api,env:"staging"} then P={railway,api,env:"production"}, in that order | `[S]` (no reordering toward production) |

