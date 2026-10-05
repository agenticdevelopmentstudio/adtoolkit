
**Decision**: `LanguageConfigurationStore` keys registrations by an opaque incrementing handle rather than by `languageId`.
**Rationale**: upstream VS Code allows more than one configuration per language, each with its own `Disposable` (`extHostLanguageFeatures.ts`'s own handle-minting pair). An id-keyed store could not express two extensions configuring the same language without one silently overwriting the other, and could not implement `dispose()` correctly when they do; keying by handle, as this file does, lets both survive and lets each be disposed independently.
**Approved**: pending

**Decision**: `wordPatternRefusal(for:)` treats "fails to compile under `NSRegularExpression`" and "compiles and matches the empty string" as two different outcomes — only the second is a refusal — rather than collapsing both into a single "invalid pattern" refusal.
**Rationale**: `NSRegularExpression` (ICU) and V8 (upstream's own regex engine) do not accept identical pattern syntax; a pattern real VS Code accepts can fail to compile under ICU for reasons that have nothing to do with the actual refusal upstream implements (`extHostLanguageFeatures.ts`'s empty-match check). Inventing a second refusal for an engine mismatch would reject configurations upstream itself allows, so a non-compiling pattern is stored unvalidated and logged instead.
**Approved**: pending

**Decision**: numeric fields this file reads from JavaScript (`indentAction`, `notIn` elements, `removeText`) are converted with `Int32(exactly:)`, never `toInt32()`.
**Rationale**: `toInt32()` implements ECMAScript's `ToInt32`, which wraps modulo 2³² and truncates fractions, so a value like `4294967297` would read as the in-range integer `1` and be silently accepted as a valid `IndentAction`/`SyntaxTokenType`/`removeText` when it is none of those things. `Int32(exactly:)` answers `nil` for any value that is not exactly representable, so this file refuses the whole field (or the whole rule, when the field is required) instead of accepting a value JavaScript never actually meant.
**Approved**: pending

**Decision**: `__electricCharacterSupport` and `__characterPairSupport` are accepted without raising and their values are discarded with no deprecation report.
**Rationale**: upstream reports both through its own deprecation-reporting mechanism and then forwards them to its wire unchanged; this bridge has neither that reporter nor a wire for either member to reach, so storing a value nothing here ever reads would be worse than an honest absence. An extension that still sets either member gets silence rather than the warning real VS Code gives it, because there is nowhere in this bridge to send that warning — a deliberate, documented divergence from upstream rather than a description of it.
**Approved**: pending

