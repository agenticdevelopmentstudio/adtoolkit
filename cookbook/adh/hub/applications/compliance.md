
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | failed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

`separation-of-concerns` passes: `ApplicationsDataSource` isolates every network call behind a
protocol `ApplicationsTopic` depends on but never implements, and the wire/domain model split
(`ApplicationsModels.swift`'s `Codable` types vs. the non-`Codable` `CrudPermissions`/
`TableGrant`/`SchemaGrant`) keeps the API's exact shape out of the domain layer. `unit-test-coverage`
passes: `ApplicationsTopicTests.swift` exercises every operation with a fake data source, including
the rename/re-home sequence, the reveal-once/expiry mechanic, and multiple failure paths.
`explicit-error-handling` passes: every throwing path in `ApplicationsTopic` routes through
`HubError.wrap(_:)` or a specific `catch HubError.conflict`/`.notFound` mapping — nothing is
silently discarded. `secure-storage` passes: no plaintext token secret is ever written to disk,
`UserDefaults`, or the Keychain — `revealedSecrets` is transient, in-memory, and actively
self-expiring. `no-hardcoded-strings` fails outright — see Localization; there is no localization
mechanism anywhere in these three files. `error-recovery` fails: none of the three files retries,
backs off, or queues a failed call — every `ApplicationsDataSource`/`BucketsDataSource` invocation
is a single `try await` that throws straight through to the caller on any failure, transient or
not. `data-integrity` is `partial`: individual writes are internally consistent (each
`setSchemaGrants` call replaces the array atomically from the caller's point of view, and
`table-grant-ceiling-enforcement` validates cross-field consistency before a save), but see the
grants-write-last-writer-wins requirement — the whole-list read-modify-write pattern has no
protection against two overlapping writers silently discarding one another's changes.

