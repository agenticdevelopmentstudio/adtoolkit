
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | passed | Performance |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |

`separation-of-concerns` **passed**: this file is pure data-layer
infrastructure — a cache client, a provider, and a subscription guard — with
no presentation code and no domain-specific fetch logic of its own; every
concrete query lives in a sibling file (see the resource-data component and the other data components that consume this client). `unit-test-coverage` is **partial**: the
singleton, per-call-server, provider-nesting, and context-independence
behaviors are all directly asserted by `query-client.test.tsx` and
`toolkit-query-provider.test.tsx`, but `watchSession`'s entire
session-change contract — the initial subject capture, the compare-then-clear
guard, and the cross-tab `'storage'` listener — has no test exercising it
anywhere in this package (see the open question recorded against
`session-change-clears-on-subject-change` in the Conformance Test Vectors).
`caching-strategy` **passed**: this file is the single place that defines
the shared invalidation policy (5-minute `staleTime`, single retry, a
30-minute `gcTime` pinned by key prefix so a prefetch or a post-write
`setQueryData` survives as long as an observed read) every toolkit query
inherits, plus the whole-cache invalidation on principal change; the actual
remote fetches these policies govern are documented by the recipes for the
queries that make them. `fault-tolerance` **passed**: the module tolerates
every unpredictable-state shape its own tests exercise — server vs. browser
execution, a provider nested inside another, sibling providers, no provider
at all, and a host's own differently-configured `QueryClientProvider` —
without ever throwing or adopting the wrong client. `data-integrity`
**passed**: `watchSession`'s whole-cache clear on a principal change is
exactly a corrupt-data guard — it exists specifically to stop a second
signed-in principal from reading data cached under the first, and it is a
second, independent layer against that on top of the tenant-keyed cache
segments the resource-data component describes. `data-minimization` **passed**: the
only identity value this file reads, `readTokenSubject()`'s `sub` claim, is
held only in an in-memory comparison variable and is never persisted,
transmitted, or exposed beyond that comparison.

