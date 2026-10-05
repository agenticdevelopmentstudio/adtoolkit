
| Check | Status | Category |
|-------|--------|----------|
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`secure-storage` is **partial**: the refresh token is deliberately never
persisted client-side and the CSRF nonce/return-to path live in
short-lived `sessionStorage`, but the access token and cached user object
sit in plaintext `localStorage` with no encryption — an accepted SPA
tradeoff (see Privacy), not full conformance. `input-sanitization` is
**partial**: `safeReturnTo` strictly validates and normalizes its one
security-sensitive input (the return-to URL), but credentials, MFA codes,
and OAuth codes/identifiers pass through every request body unvalidated by
this client, relying entirely on the server. `explicit-error-handling`
**passed**: every failure path in these 11 files either throws a typed
`AuthHttpError`/`Error` the caller can branch on, or (in `report.ts`) is an
intentional fail-safe swallow of a telemetry sink's own failure — no path
silently drops a primary operation's error. `fault-tolerance` **passed**:
the refresh single-flight/generation/resurrection guards, the loser-recheck
window, and `exchangeSsoCode`'s bounded retry all exist specifically to keep
concurrent and transient-failure paths from corrupting session state.
`data-minimization` **passed**: the refresh token is never collected;
`ErrorContext` is typed scalars-only. `no-pii-in-logs` **passed**: every
`console.error` call logs only an `Error` object and a declared
scalar-only context, never a request body or token. `no-hardcoded-strings`
**failed**: every user-facing string in `labels.ts`, `mfa.ts`, and
`client.ts`'s fallbacks is hardcoded English with no lookup table or locale
parameter anywhere in this component (see Localization) — this is a plain,
honestly-reported gap in the source, not a hidden one.

`separation-of-concerns` passes because each of the eleven source files owns one concern with no overlap — `tokens.ts` token storage, `refresh.ts` the refresh single-flight, `sso.ts` SSO hint and return-to handling, `report.ts` the telemetry sink, `client.ts` the HTTP calls, `mfa.ts` and `account-security.ts` their endpoint families, `config.ts`, `labels.ts` and `types.ts` configuration, copy and shapes. `unit-test-coverage` is partial because `client.test.ts`, `refresh.test.ts`, `sso.test.ts`, `tokens.test.ts`, `report.test.ts`, `silent-restore.test.ts`, `link.test.ts` and `types.test.ts` in the auth package's `__tests__` directory cover the core flows, but `mfa.ts`, `account-security.ts` and `asBase.ts` have no dedicated test file.

