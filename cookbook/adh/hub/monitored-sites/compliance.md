
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |
| [pagination-support](agenticdevelopercookbook://compliance/access-patterns#pagination-support) | failed | Access Patterns |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | failed | Reliability |

`separation-of-concerns` passes: `monitored-sites.ts`/`wire.ts` contain zero UI or presentation code —
both files are the public data-domain surface consumed by the separate Dashboards presentation layer.
`unit-test-coverage` is `partial`: of the twelve exported functions plus three mappers,
`monitored-sites.test.ts` covers only the three mappers (`toGroup`, `toSite`, `toEndpoint`); none of
`listGroups`/`createGroup`/`updateGroup`/`deleteGroup`/`listSites`/`createSite`/`updateSite`/`deleteSite`/`listEndpoints`/`createEndpoint`/`updateEndpoint`/`deleteEndpoint`
has a dedicated test in this checkout. `explicit-error-handling` passes: nothing in this file swallows an
error — every failure either throws `AuthHttpError` (via the shared `authedFetch`) or propagates
unmodified. `server-side-authorization` passes: the module contains no client-side permission check of any
kind, per `owner-scoping-server-side`, deferring owner/workspace scoping entirely to the backend.
`error-response-handling` is `partial`: every call exposes a status and optional code for the caller to
branch on, but no function in this file offers per-code handling of its own (no `rethrowConflict`, no
`isNotFound`/`isConflict` branch) — every failure surfaces as the generic `AuthHttpError` propagation.
`pagination-support` fails: `listGroups`, `listSites`, and `listEndpoints` all return unpaginated
collections with no limit/cursor parameter, against a backend the source's own comment documents as
capping generic-CRUD lists at 500 rows, with no truncation signal to the caller. `graceful-degradation`
fails: unlike a sibling client's documented fallback constant, this module offers no fallback of any kind
when a call fails — every failure is an unhandled rejection with no degraded-but-functional path.

