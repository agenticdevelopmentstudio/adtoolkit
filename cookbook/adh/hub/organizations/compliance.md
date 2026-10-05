
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | Access Patterns |
| [offline-behavior](agenticdevelopercookbook://compliance/access-patterns#offline-behavior) | failed | Access Patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`separation-of-concerns` **passed**: `organizations.ts`/`members.ts` contain zero UI or
presentation code, `wire.ts` is a type-only file, and `index.ts`'s own comment describes the module
as the public surface of a data domain, consumed by a separate presentation layer.
`explicit-error-handling` **passed**: nothing in either file swallows an error — every failure
either throws `AuthHttpError` (via the shared `authedFetch`) or one of the two hand-authored
friendly `Error`s this recipe documents. `unit-test-coverage` **failed**: no `__tests__` directory
or `*.test.ts` file exists next to `organizations.ts`/`members.ts` in this checkout, and the
consumer feature tests found elsewhere in the repository (`NewOrganizationModal.test.tsx`,
`orgRenameSavePath.test.tsx`) mock `@agentic-toolkit/data/organizations` wholesale rather than
exercising this module's own request-building or error-mapping logic — none of the requirements
above is exercised by a dedicated test in this checkout. `server-side-authorization` **passed**:
neither module performs a client-side permission check of any kind, per
`authorization-enforced-server-side`, deferring the workspace-kind and field-level authorization
splits, the archive role set, and the roster membership gate entirely to the backend.
`input-sanitization` **partial**: no file client-side validates `slug`/`name`/`description`
character set or length before sending; the backend's own uniqueness constraint and validation are
the sole authority this client deliberately relies on rather than duplicating (see Edge Cases).
`error-response-handling` **passed**: `rethrowConflict`/`isConflict` and the plain `AuthHttpError`
propagation consistently distinguish a slug conflict (`create`/`rename`), a handle-taken conflict
(`restore`), and every other failure, on every method. `retry-with-backoff` **failed**: no file
retries a failed organizations/roster request beyond the inherited 401-refresh-and-retry-once,
which is a different, cross-cutting auth concern (see `auth-client`), not a retry of this domain's
own operations. `offline-behavior` **failed**: neither module defines an offline-cache-first read
path or a queued-write-when-offline behavior; every operation is a live round-trip that fails
outright when the network is unavailable. `idempotent-operations` **partial**: `rename`'s PATCH is
a plain field update with no stated idempotency guarantee of its own (unlike the sibling Ecosystems
client's documented locked-value diff), and `create`/`restore` have no idempotency key on the
client side — a client-level retry of either (were one ever added) could not safely be
distinguished from a genuine duplicate request. `data-minimization` **passed**: every organization
field this component reads or writes is administrative metadata, and the roster's personal fields
(`email`, `displayName`) are already nulled server-side outside the caller's own ecosystem before
this client ever sees them. `no-hardcoded-strings` **failed**: the three hand-authored conflict
messages this recipe documents are fixed English with no lookup table or locale parameter in either
file (see Localization) — a plain, honestly-reported gap, not a hidden one.

