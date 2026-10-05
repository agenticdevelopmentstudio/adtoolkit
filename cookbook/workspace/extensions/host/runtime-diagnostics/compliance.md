
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |
| [health-observability](agenticdevelopercookbook://compliance/reliability#health-observability) | partial | Reliability |
| [resource-efficiency](agenticdevelopercookbook://compliance/performance#resource-efficiency) | partial | Performance |

Notes: separation-of-concerns passes because `JITAvailability` and
`UpstreamDivergence` are self-contained value types with no dependency on
any UI or infrastructure layer, and `UpstreamDivergenceLedger` exposes only
`hits`, `hits(for:)`, and `hitsPublisher` as its seam — a consumer such as
the Language Servers settings panel never touches its `NSLock` or
dictionary directly, and every recorder depends on the concrete
`UpstreamDivergenceLedger` type through constructor injection defaulting to
`.shared`, never a bare global function. unit-test-coverage passes because
`JITAvailabilityTests.swift` exercises every `isHardenedRuntime`/`hasJITEntitlement`
combination and the memoization/stability of `current`/`probe()`, and
`UpstreamDivergenceLedgerTests.swift` plus `UpstreamDivergenceCatalogueTests`
exercise accumulation, row keying, sorting, filtering, publishing, clearing,
non-positive counts, 200-way concurrent recording, and every catalogue
invariant. secure-log-output passes because the only strings either type
logs are the fixed `diagnosis` prose and, in the ledger, the divergence's
`id` and its fixed `ourBehaviour` catalogue text, plus a caller-supplied
`detail` that the source's own doc comment restricts to a document URI or
server name — never a credential, token, or document's contents.
health-observability is partial because both types log only on a state
transition — `JITAvailability` at most once per process, the ledger only on
a key's first-ever hit — with nothing emitted on any periodic cadence, so a
monitoring system reading logs alone cannot distinguish "still healthy" from
"never checked since the last transition." resource-efficiency is partial
because, while both types are cheap at idle, `UpstreamDivergenceLedger` has
no eviction policy or row cap (see the "Unbounded ledger growth" edge case
and its Design Decisions entry), so a long session touching many distinct
documents grows `rows` without bound until an explicit `clear()`.

