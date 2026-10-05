
### Title heuristic contract

- **heuristic-name**: A title heuristic MUST expose `name`, a user-visible string (for example "Xcode").
- **heuristic-app-names**: A title heuristic MUST expose `appNames`, the owning-application names it applies to, compared against the window owner name reported by the window server (for example "Xcode", "Brave Browser", "Code").
- **heuristic-extract-pattern**: Extracting the pattern from a title MUST return the stable identifying portion of a raw title, or nil when the title does not match the heuristic's expected format.
- **heuristic-default-strategy**: When a heuristic does not override `recommendedStrategy`, it MUST be the app-and-title-substring strategy.
- **heuristic-default-fingerprint-pattern**: When a heuristic does not override its fingerprint-pattern production, that production MUST return the extracted pattern for the title paired with `recommendedStrategy`, or nil when extraction returns nil.
- **heuristic-sendable**: A title heuristic MUST be safe to share across concurrent contexts (see Platform Notes for the isolation mechanism).

### Title parsing

- **parser-separators**: The shared title parser's separators MUST be, in order, space + em dash (U+2014) + space, then space + en dash (U+2013) + space.
- **parser-first-separator-wins**: Splitting a title into components MUST split on the first separator in that order that the title contains, and only on that separator.
- **parser-trim**: Each returned component MUST be trimmed of leading and trailing spaces and tabs (whitespace, not newlines).
- **parser-no-separator**: When the title contains no separator, splitting it MUST return a single element: the trimmed title.
- **parser-en-dash-split**: A title whose content contains " – " (en dash with spaces) MUST be split there when it contains no em-dash separator; this trade-off is intentional (see Design Decisions).

### Custom rule shape and matching

- **match-mode-cases**: A rule's match mode MUST have exactly two cases, `substring` and `regex`, encoded as the strings `"substring"` and `"regex"`.
- **match-mode-display-name**: The match mode's display name MUST return "Substring" for substring mode and "Regex" for regex mode.
- **rule-fields**: A custom heuristic rule MUST carry `id` (unique identifier, immutable), `appName`, `titlePattern`, `matchMode`, `autoAssign`, `targetContextName` (optional), `name`, and `createdAt` (timestamp, immutable).
- **rule-init-defaults**: Creating a rule MUST default `id` to a newly generated unique identifier, `matchMode` to substring, `autoAssign` to false, `targetContextName` to nil, `name` to empty, and `createdAt` to the current date.
- **rule-default-name**: When `name` is empty at creation, the rule's `name` MUST become `"<appName> - <titlePattern>"`.
- **rule-value-semantics**: A custom heuristic rule MUST be serializable to and from JSON, comparable for equality, uniquely identifiable, and safe to share across concurrent contexts.
- **rule-empty-pattern**: Testing a title against the rule MUST return nil for every title when `titlePattern` is empty.
- **rule-substring-match**: In substring mode, testing a title MUST return `titlePattern` itself (not the title's matching slice) when the title contains it under a locale-aware case-insensitive comparison, and nil otherwise.
- **rule-regex-match**: In regex mode, testing a title MUST compile `titlePattern` as a case-insensitive regular expression and return the text of the first match in the title.
- **rule-regex-non-empty**: In regex mode, a zero-length first match (for example from a pattern that matches everywhere in an empty title, a start anchor, or a word-boundary pattern) MUST yield nil.
- **rule-regex-invalid**: In regex mode, an uncompilable pattern MUST yield nil and MUST log one error-level message containing the pattern and the compiler's reason, on every call.
- **rule-regex-unmappable-range**: In regex mode, a match whose range cannot be mapped back onto the title's characters MUST yield nil rather than crash.
- **rule-app-name-case**: The rule's `appName` MUST be matched case-insensitively against the window owner name (enforced by the registry's lowercased key, see registry-case-insensitive).
- **rule-auto-assign**: `autoAssign` and `targetContextName` are consumed outside this component, by the context manager's auto-assignment check: for a window not already in any context, it walks its own custom rules in order and, for the first rule with `autoAssign` true, a case-insensitive `appName` match, a title match and a `targetContextName` that names an existing context (case-insensitively), adds the window to that context. A rule whose target context does not exist is skipped. This recipe's types only carry the fields; a port MUST keep them so that consumer can read them.

### Custom-rule heuristic adapter

- **custom-name**: The custom-rule adapter's `name` MUST equal the rule's `name`.
- **custom-app-names**: The adapter's `appNames` MUST be the one-element list containing the rule's `appName`.
- **custom-extract**: The adapter's pattern extraction MUST return the result of testing the title against the rule.
- **custom-strategy**: The adapter's `recommendedStrategy` MUST be the app-and-title-regex strategy for a regex rule and the app-and-title-substring strategy for a substring rule.
- **custom-fingerprint-unmatched**: The adapter's fingerprint-pattern production MUST return nil when the rule does not match the title.
- **custom-fingerprint-substring**: For a matching title and a substring rule, fingerprint-pattern production MUST return the rule's `titlePattern` paired with the app-and-title-substring strategy.
- **custom-fingerprint-regex**: For a matching title and a regex rule, fingerprint-pattern production MUST return the regex source paired with the app-and-title-regex strategy, never the captured text, so sibling titles ("JIRA-1234", "JIRA-9999") re-match the same fingerprint.

### Rule store

- **store-root**: The rule store MUST store rules in a caller-supplied root directory; it MUST NOT choose an application-specific location itself.
- **store-file-path**: The rules file path MUST be `<root directory>/heuristics.json`.
- **store-load-missing**: Loading rules MUST return an empty list when `heuristics.json` does not exist.
- **store-load-decode**: Loading rules MUST decode the file as a JSON array of rules with ISO 8601 dates.
- **store-load-errors**: Loading rules MUST throw the underlying read or decoding error unchanged when the file exists but cannot be read or decoded; it MUST NOT fall back to an empty list in that case.
- **store-save-directory**: Saving rules MUST create the root directory, including intermediate directories, when it does not exist.
- **store-save-format**: Saving rules MUST encode the full rule list as pretty-printed JSON with sorted keys and ISO 8601 dates.
- **store-save-atomic**: Saving rules MUST write the file atomically, replacing the previous contents in full; it MUST throw any directory-creation, encoding or write error.
- **store-remove-all**: Clearing all rules MUST delete `heuristics.json` when it exists, MUST do nothing when it does not, and MUST NOT delete the root directory.
- **store-isolation**: The rule store MUST be used from one execution context at a time; its operations are synchronous, blocking file I/O.
- **store-no-cache**: The store MUST NOT cache rules in memory; each load reads the file.

### Heuristic registry

- **registry-built-ins**: The registry's built-in heuristics MUST be, in order, the Xcode heuristic, the Warp heuristic, the Brave heuristic, the VS Code heuristic and the Terminal heuristic, covering the app names "Xcode", "Warp", "Brave Browser", "Code", "Visual Studio Code", "Cursor" and "Terminal".
- **registry-shared**: The registry's shared instance MUST be a process-wide instance initialized with the built-ins.
- **registry-init**: Creating a registry MUST register the given heuristics, or the built-ins when none are given, in list order.
- **registry-case-insensitive**: Looking up the heuristic for an app name MUST match case-insensitively and return nil when no heuristic is registered for it.
- **registry-last-wins**: When two registered heuristics claim the same app name, the one registered later MUST be returned by the lookup.
- **registry-register**: Registering a heuristic MUST append it to the registry's heuristic list and map each of its `appNames`, overwriting any earlier mapping for that name.
- **registry-custom-replace**: Registering the custom rules MUST remove every previously registered custom-rule adapter, rebuild the lookup from the remaining heuristics, store the new rules as `customRules`, and then register one adapter per rule in list order.
- **registry-custom-overrides**: After registering the custom rules, a custom rule for an app name MUST take precedence over a built-in or explicitly registered heuristic for the same name.
- **registry-custom-clear**: Registering an empty list of custom rules MUST restore the lookup to the non-custom heuristics and leave `customRules` empty.
- **duplicate-app-rules**: Custom rules are last-wins per app name. When two custom rules target the same app name, only the later one is returned by the lookup and so used for fingerprinting and scoring; the earlier rule stays in `customRules` (and in the Settings list) but is not consulted by the registry, and nothing rejects or reports the duplicate.
- **registry-is-built-in**: Checking whether an app name is built in MUST return false when any registered custom rule targets that app name (case-insensitive); otherwise it MUST return true exactly when a heuristic in the fixed built-in list claims the name, regardless of which heuristics this registry instance was created with.
- **registry-snapshots**: The registry's heuristic list and `customRules` MUST return copies taken under a lock, in registration order.
- **registry-thread-safety**: Every read and write of the registry's mutable state MUST be serialized by one lock, so any single call is atomic and the registry is safe to share across threads.
- **registry-no-cross-call-snapshot**: The registry MUST NOT be assumed consistent across separate calls: the window matcher performs one lookup per fingerprint-or-score call, so a caller that mutates custom rules concurrently with a re-matching run can score different pairs against different rule sets. In the toolkit, the context manager confines its calls to a single thread and is the only caller that registers custom rules, ordering its writes against its own matching.

### Window matcher — fingerprinting

- **matcher-registry**: The window matcher MUST use the injected registry, defaulting to the registry's shared instance.
- **matcher-isolation**: The window matcher MUST hold no mutable state; every operation is synchronous and pure except for logging.
- **fingerprint-heuristic**: Fingerprinting a live window MUST, when a heuristic is registered for the window's app and its fingerprint-pattern production for the window's title is non-nil, return a fingerprint with that pattern and strategy.
- **fingerprint-fallback**: When no heuristic is registered or it returns nil, fingerprinting MUST use the window's full title as `titlePattern` with the app-and-title-substring strategy.
- **fingerprint-empty-title**: When falling back and the window's title is empty, the strategy MUST be app-only (with an empty `titlePattern`).
- **fingerprint-app-display**: Every fingerprint MUST copy the window's app (unchanged, original case) and display into its own app and display fields.
- **fingerprint-never-exact**: Fingerprinting MUST NOT produce the app-and-title-exact strategy unless a registered heuristic's fingerprint-pattern production returns it; no built-in heuristic does, so that strategy only arises from fingerprints constructed elsewhere.

### Window matcher — scoring

- **score-app-gate**: Scoring a live window against a fingerprint MUST return 0 when the window's app and the fingerprint's app differ after lowercasing.
- **score-live-pattern**: For the exact and substring strategies, the live pattern MUST be the registered heuristic's extracted pattern for the window's title when non-nil, else the window's raw title.
- **score-exact**: Under the app-and-title-exact strategy, the title component MUST be 80 when the lowercased live pattern equals the lowercased `titlePattern`, and the total score MUST be 0 otherwise.
- **score-substring-equal**: Under the app-and-title-substring strategy, the title component MUST be 80 when the lowercased live pattern equals the lowercased `titlePattern`.
- **score-substring-contains**: Under the app-and-title-substring strategy, when not equal, the title component MUST be 60 when the lowercased pattern is at least the minimum substring pattern length (2) characters and is contained in the lowercased live pattern or the lowercased raw title.
- **score-substring-direction**: Substring matching MUST test only "live contains stored pattern"; a stored pattern that contains the live token MUST NOT match.
- **score-substring-miss**: Under the app-and-title-substring strategy, when neither equality nor containment holds, the total score MUST be 0.
- **score-regex**: Under the app-and-title-regex strategy, the title component MUST be 80 when `titlePattern`, compiled case-insensitively, has a first match of non-zero length in the window's raw title, and the total score MUST be 0 otherwise; the app's heuristic MUST NOT be consulted.
- **score-regex-invalid**: Under the app-and-title-regex strategy, an empty or uncompilable `titlePattern` MUST score 0; an uncompilable one MUST also log one error-level message with the pattern and reason, on every call.
- **score-app-only**: Under the app-only strategy, the title component MUST be 80 regardless of title.
- **score-display-bonus**: When the title component is non-zero, the score MUST add 10 when the window's display equals the fingerprint's display.
- **score-range**: Every score MUST be one of 0, 60, 70, 80 or 90.

### Window matcher — re-matching

- **match-constants**: The auto-assign threshold MUST be 80 and the minimum substring pattern length MUST be 2.
- **match-default-threshold**: Re-matching dormant snapshots against live windows MUST default its threshold to the auto-assign threshold.
- **match-dormant-only**: Only snapshots with no assigned window ID MUST be candidates for re-matching.
- **match-exclude-assigned**: A live window whose ID equals any snapshot's assigned window ID (in any context) MUST be excluded from candidates and from `unassignedWindows`.
- **match-threshold-filter**: Only pairs scoring at least the threshold MUST become candidates; lower-scoring pairs MUST NOT consume a snapshot or a window.
- **match-order**: Candidates MUST be ordered by score descending, then the context ID's string form ascending, then the snapshot ID's string form ascending, then window ID ascending, so equal inputs always yield equal results.
- **match-greedy**: Walking candidates in that order, a candidate MUST be accepted only when neither its snapshot ID nor its window ID has already been accepted.
- **match-unmatched**: `unmatchedSnapshots` MUST list every dormant snapshot not accepted, as `(contextID, snapshotID)`, in context order then snapshot order.
- **match-unassigned**: `unassignedWindows` MUST list every candidate window not accepted, in the order the live windows were given.
- **match-result-order**: `matched` MUST list accepted candidates in acceptance order.
- **match-substring-default**: With the default threshold of 80, a substring-containment match (60, or 70 with the display bonus) MUST NOT be auto-assigned.
- **candidate-match-shape**: A candidate match MUST carry `contextID`, `snapshotID`, `window` (a live window record) and `score`, and be comparable by all four.
- **match-result-equality**: Comparing two match results for equality MUST compare `matched` and `unassignedWindows` element-wise and `unmatchedSnapshots` by count and element-wise `contextID` and `snapshotID`.
- **match-no-side-effects**: Re-matching MUST NOT mutate contexts, snapshots or the registry; applying the result is the caller's job (the context manager).

