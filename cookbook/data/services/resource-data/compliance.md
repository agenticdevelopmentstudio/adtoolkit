
| Check | Status | Category |
|-------|--------|----------|
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`secure-storage` is **partial**: the FTD last-id/view-mode values and the
cached workspace slug sit in plaintext `localStorage` with no encryption —
an accepted SPA tradeoff (see Privacy), though none of these values is
itself a credential, unlike the access token `auth-client`'s own
`secure-storage` row covers. `input-sanitization` **passed**: every dynamic
path segment this component builds into a URL
(`workspaceQuery`, `checkWorkspaceSlugAvailable`'s slug) is passed through
`enc`/`encodeURIComponent` before interpolation. `explicit-error-handling`
**passed**: every read/write path in these nine files either rethrows a
caller-visible error or falls back to a documented default — the two
deliberate swallow paths (storage exceptions; `makeEntityDeleteHandler`'s
post-delete `reload()`) are each covered by their own Design Decisions
entry, not silent omissions. `fault-tolerance` **passed**: `retry: false`
plus the long `RESOURCE_GC_TIME`, the storage-exception swallowing, and the
del-not-caught/reload-swallowed split in `makeEntityDeleteHandler`
collectively keep a transient or permission failure from corrupting cache
state or crashing a render. `data-integrity` **passed**: tenant-keyed cache
segments make cross-tenant leakage structurally impossible rather than
merely policed, and `useResourceItemWriter`'s evict-not-tombstone choice
means a deleted row can never be misread back as a cached empty answer.
`data-minimization` **passed**: this component collects no personal data of
its own beyond the opaque `tenantId` it reads via `useTenantId()`.
`no-hardcoded-strings` **failed**: the `'Failed to load.'` fallback in
`use-resource-item.ts`/`use-resource-list.ts` is hardcoded English with no
lookup table or locale parameter anywhere in this component (see
Localization) — a plain, honestly-reported gap in the source, not a hidden
one.

`separation-of-concerns` passes because each of the nine source files owns one concern — `http.ts` request helpers, `tenant.ts` the tenant-id read state, `ftd-storage.ts` and `workspace-prefs.ts` browser persistence, `use-resource-item.ts` and `use-resource-list.ts` the read states over the shared cache, `workspaces.ts` the workspace announcements, `config.ts` the host-injectable prefix, `client-helpers.ts` pure list helpers — with no presentation code. `unit-test-coverage` is partial because `use-resource-item.test.tsx`, `use-resource-list.test.tsx`, `ftd-storage.test.ts`, `http.test.ts`, `tenant.test.ts`, `workspace-prefs.test.ts` and `workspaces-changed.test.ts` in the data package's `__tests__` directory cover most behaviors, but `client-helpers.ts`, `config.ts` and the workspace slug-availability check in `workspaces.ts` have no dedicated test file, and the reload-without-id behavior is untested.

