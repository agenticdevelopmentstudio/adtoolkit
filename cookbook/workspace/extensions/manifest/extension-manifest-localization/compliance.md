
| Check | Status | Category |
|-------|--------|----------|
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`explicit-error-handling` is **failed**: every failure this file can
encounter — an unreadable directory, an unreadable table file, malformed
JSON/JSONC, an unserializable rewritten tree — is caught with `try?` and
discarded with no signal of any kind, not a thrown error, not a return
value, and not a `DecodingFailure`-style record the way `ExtensionManifest`
produces for its own decode failures (see Logging and Design Decisions).
`fault-tolerance` **passed**: `localize` never throws and every one of its
internal helpers has a defined, total fallback for every failure mode.
`data-integrity` is **partial**: when a table is present, the manifest is
rewritten by parsing and re-serializing through `JSONSerialization`, which
is not a byte-identical round trip — key order and number formatting can
change — though this is only exercised when at least one placeholder needs
resolving (**unchanged-when-no-table** avoids it entirely otherwise).
`idempotent-operations` **passed**: `localize` is a pure function of its
three arguments and the current contents of `directory`; two calls with
unchanged inputs produce identical output. `separation-of-concerns`
**passed**: this file's sole responsibility is placeholder resolution,
sitting beside the manifest it serves and shared by both of its readers
rather than duplicated in each. `unit-test-coverage`
**passed**: `ExtensionManifestLocalizationTests.swift` exercises the default
table, language and region preference, gap fill-in from the default table,
fallback to the default for an untranslated locale, both table-entry
shapes, the byte-identical no-op path, an unresolved key staying visible, a
non-placeholder string containing `%` being left alone, an unreadable table
not sinking the manifest, and non-string values surviving the rewrite.

