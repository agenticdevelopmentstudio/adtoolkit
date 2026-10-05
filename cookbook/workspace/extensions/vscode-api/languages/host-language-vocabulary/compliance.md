
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |

`separation-of-concerns` passes because `HostLanguageVocabulary` does
exactly one thing — compose two already-deterministic identifier sources
into one deduplicated, ordered array behind a single computed property —
and delegates all decoding, manifest parsing, and JS/Swift bridging to
`LanguageContributionPoint` and `MainThreadLanguages` respectively
(`Overview`, `protocol-conformance`, `computed-not-cached`).
`unit-test-coverage` passes because `MainThreadLanguagesVocabularyTests.swift`'s
`HostLanguageVocabularyTests` suite exercises the production conformer
directly — never a double for either side — asserting the built-in/contributed
dedup, the presence of `CodeLanguage.default`'s identifier, and the
built-ins-first ordering (`hlv-001` through `hlv-003`).
`good-test-properties` passes because each test in that suite constructs
its own `LanguageContributionPoint` and `HostLanguageVocabulary`, asserts a
single concrete outcome with `#expect`/`#require`, and shares no mutable
fixture state across tests, so every test is fast, isolated, repeatable,
and self-validating.
`fault-tolerance` passes because the built-in loop's `seen.insert` guard
and the contributed loop's `where seen.insert(id).inserted` clause together
ensure that any number of duplicate or unexpected identifiers from either
source — including a contribution that names an existing built-in exactly —
are absorbed by deduplication rather than causing a crash or a corrupted
result (`built-in-deduplication`, `contributed-deduplication`, Edge Cases
— Boundary values).

