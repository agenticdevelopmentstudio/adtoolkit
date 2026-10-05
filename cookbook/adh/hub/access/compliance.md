
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | partial | Reliability |

`separation-of-concerns` passes: `access.ts`/`wire.ts` contain zero UI or presentation code — both the
module's own top comment and `index.ts`'s comment describe it as the public surface of a data domain,
consumed by a separate presentation layer. `unit-test-coverage` is `partial`: of `accessApi`'s ten
methods, only `listFeatures` has dedicated unit tests (`access.test.ts`'s comment says as much
explicitly — every other consumer test mocks this package wholesale); `listRoles`, `createRole`,
`updateRole`, `deleteRole`, `listAssignments`, `putAssignment`, `deleteAssignment`, `restrictItem`,
`restoreItem`, and `effective` have none in this checkout. `explicit-error-handling` passes: nothing
in this file swallows an error — every failure either throws `AuthHttpError` (via the shared
`authedFetch`) or the plain validation `Error` `listFeatures` raises itself. `server-side-authorization`
passes: the module contains no client-side permission check of any kind, per `authorization-enforced-server-side`,
deferring membership, admin-only role edits, and the manage-access verb requirement entirely to the
backend. `error-response-handling` is `partial`: every call exposes a status and optional code for the
caller to branch on, but only `listFeatures`'s doc comment describes a specific, documented fallback
contract for one status (a `404` meaning "this backend predates the route") — and even that fallback
is implemented by the caller, not by this module; the other nine methods offer no per-code handling
beyond the generic `AuthHttpError` propagation. `graceful-degradation` is `partial`: `ACCESS_FEATURES`
exists as an explicit, documented escape hatch for exactly this situation, but `listFeatures` does not
apply it itself — degradation is opt-in by the caller, not automatic within this component, and no
other method offers a fallback of any kind.

