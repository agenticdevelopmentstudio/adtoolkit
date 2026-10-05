
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |

Notes: graceful-degradation passes because every malformed or unexpected
input — an unparseable `baseURL`, a `baseURL` that trims to empty, garbage
JSON, or a JSON entry with wrong-typed fields — resolves to `false`, `nil`,
or `[:]` rather than a thrown error or a crash. explicit-error-handling is
partial because both the whole-document and per-entry decode failures in
`parseSizes(_:)` are discarded via `try?` with zero diagnostic signal, so a
caller cannot distinguish "server returned no models" from "server returned
garbage" (see Logging). data-integrity is partial because
`parse-sizes-array-order-last-write-wins` lets two distinct `models`
entries silently overwrite each other's size under a colliding `name`/`model`
key, with no validation or reported conflict. no-hardcoded-strings passes
because the source contains no user-facing string literal at all to
hardcode — its only string literals are the fixed `loopbackHosts` set, the
`"/v1"` and `"/api/tags"` path fragments, and JSON key names, none of which
is displayed to a user (see Localization).

`separation-of-concerns` passes because `LocalModelServer` holds only pure helpers (loopback detection, tags URL derivation, size parsing and lookup) with no I/O or cache of its own; fetching and caching live in `LocalModelCatalog` and `LocalProviderModelStore`. `unit-test-coverage` passes because `LocalModelServerTests.swift` covers loopback versus remote hosts, stripping the `/v1` suffix from the tags URL, indexing both name and model keys with `:latest` tolerance, garbage input, and a malformed entry not discarding the rest of the listing.

