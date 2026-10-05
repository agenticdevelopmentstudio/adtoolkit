
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |

Notes: no-hardcoded-strings fails because `title` and `detail` return
English-only literals with no localization mechanism (see Localization).
idempotent-operations passes because every function on `ModelCapability`
is a pure, stateless function of its arguments (see `pure-and-stateless`
and the Concurrent access edge case). separation-of-concerns passes
because the source's own doc comment draws an explicit boundary between
this type's "does it have this" axis and `ModelUseFacet`'s "what's it
good for" axis, and derives `.conversation` by calling into
`ModelUseFacet` rather than duplicating its heuristic.

`unit-test-coverage` passes because `ModelCapabilityTests.swift` exercises the type directly: a reported capability being recognised, a curated tools flag counting, chat being read out of prose, and reasoning and vision never being inferred from prose, with `ProviderPickerTests.swift` covering its use in the picker.

