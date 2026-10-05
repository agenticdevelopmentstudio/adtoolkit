
| Check | Status | Category |
|-------|--------|----------|
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`explicit-error-handling` is **partial**: every `contributes.*` array/dictionary
entry failure is recorded as a typed `DecodingFailure` the caller can act on,
but `Command.icon`'s object-form fallback and every `ConfigurationProperty`
field drop a wrong-typed value with no `DecodingFailure` recorded anywhere
— a real, documented gap between `DecodingFailure`'s own doc comment claim
and its leaf-type behavior (see Design Decisions). `fault-tolerance`
**passed**: `LenientDecoding.array`/`.dictionary`/`.value` isolate failures
at array-element, keyed-location, and single-field granularity throughout,
so one malformed entry never sinks a sibling. `data-integrity` is
**partial**: `Contributions.encode(to:)` is deliberately lossy — it omits
`decodingFailures` and every entry that failed to decode — so a round-trip
through this type is not a faithful copy of the manifest that was decoded
(**contributions-encode-lossy**). `idempotent-operations` **passed**:
decoding is a pure function of its input `Data`; two decodes of
byte-identical JSON produce `Equatable`-equal values.
`separation-of-concerns` **passed**: the element/location-isolation logic
lives once in `LenientDecoding`, shared by both `ExtensionManifest.init(from:)`
and `Contributions.init(from:)`, rather than duplicated per contribution
type. `unit-test-coverage` **passed**: `ExtensionManifestTests.swift`
exercises identity strictness, every lenient top-level field, single-object
tolerance, per-element and per-location isolation, the tri-state capability
decode, case-folded identifiers, and the `unreadableKeys` encode exclusion.
`no-hardcoded-strings` **failed**: every `describe(_:)`/`jsonName(of:)`
string is hardcoded English with no lookup table or locale parameter
anywhere in this file (see Localization) — a plain, honestly-reported gap in
the source, not a hidden one.

