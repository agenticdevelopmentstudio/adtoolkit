
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |

`unit-test-coverage` is `partial`: the re-exported `platformCanon` and `deployTargetKey` are exercised indirectly — `canon.test.ts` tests the identical underlying functions in `@agentic-toolkit/deploy-platform/canon` directly, and because this file re-exports them unchanged (canon-reexport), that coverage carries over — but `summarizeByPlatform`, `deploysForEndpoint`, `latestTerminalForEndpoint`, and `failuresForEndpoint` have no dedicated test anywhere in this package, and, per the Overview and Design Decisions above, no runtime importer either; nothing in this repository currently exercises those four functions' logic at all, in a test or in production. `separation-of-concerns` passes: the file performs no I/O, reads no configuration, and does exactly one thing — deploy-platform summarization and endpoint correlation — with the shared canonicalization delegated to the `canon` package rather than reimplemented here. `explicit-error-handling` passes: the one real failure case, an endpoint with no usable platform/project, is surfaced as an explicit `null` key from `deployTargetKey` and handled by an explicit `if (!key) return [];` guard rather than silently proceeding with a bogus correlation or throwing. `fault-tolerance` passes: every function accepts an empty `deploys` array, an `EndpointLike` with any or all of its three fields omitted, and any `DeployStatus` value its type allows (including `"unknown"`, per the open question above) without throwing.

`unit-test-coverage`'s gap is the open question on `summarizeByPlatform`, `deploysForEndpoint`, `latestTerminalForEndpoint`, and `failuresForEndpoint` — see the corresponding Design Decision above.

