
**Decision**: The JSON document value type implements equality and hashing
by hand instead of relying on compiler-synthesized, case-first conformance,
treating an integer case and a number case as equal (and equally hashing)
when the number represents that same integer exactly.
**Rationale**: A JSON decoder always decodes a JSON integer literal as the
integer case and a value written with a decimal point as the number case;
a synthesized, case-first equality would treat a re-decoded number
differently from an original integer baseline. The source's own comment
states this previously misfired a form's dirty-state baseline comparison,
leaving Save enabled on an untouched form and producing spurious discard
prompts.
**Approved**: pending

**Decision**: The date helper builds its four ISO-8601 formatters as
constants instead of constructing one per call.
**Rationale**: The source's own comment states construction is expensive
enough to show up when a rail formats a few hundred rows; both formatter
types are safe to share as immutable singletons once built and never
mutated afterward.
Platform scope: Swift/Apple platforms — `private static let` values
(`Date.ISO8601FormatStyle`/`DateFormatter`); any port should use the
equivalent shared-immutable-instance idiom for its own platform's date
formatter type.
**Approved**: pending

**Decision**: The closure-taking error normalizer declares an isolation
parameter (`isolated (any Actor)? = #isolation`) rather than leaving the
closure's isolation to the language's default inference.
**Rationale**: Without this parameter, Swift 6 strict concurrency would
force the closure `nonisolated`, breaking a `@MainActor` caller whose
closure reads and writes main-actor state without an explicit
`MainActor.run` hop. The source's own doc comment states this specific
compile-time regression is what the parameter guards against, and three of
`SupportTests.swift`'s test methods exist solely to fail to build if it
regresses.
Platform scope: Swift/Apple platforms — actor isolation is a Swift
concurrency concept with no direct analog on this recipe's other platforms
(see the WinUI 3 Platform Note).
**Approved**: pending

**Decision**: The slug-projection operation tracks a pending-hyphen flag
and only flushes it (appending one `"-"`) immediately before the next
allowed character, and only when the output built so far is non-empty —
rather than converting every disallowed character to a hyphen in place.
**Rationale**: This guarantees the slug-projection operation's non-empty
output already satisfies the slug pattern (which forbids a leading or
trailing hyphen and any run of two or more hyphens) without a second
validation pass. The ordering this depends on — never flush while the
output is empty, never flush a still-pending hyphen at end of input — is
not obvious from a single call site, which is why it is called out here
rather than left implicit.
**Approved**: pending

