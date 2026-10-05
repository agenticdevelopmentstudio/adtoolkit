
**Decision**: `localize` never throws, and every failure mode — a missing
`directory`, an unreadable or malformed table file, an unserializable
rewritten tree — degrades to "this manifest keeps its placeholders" rather
than to an error the caller must handle.
**Rationale**: The source's own doc comment states the reasoning directly:
refusing the manifest over a table's typo would turn "a typo in a file
nobody executes into an extension that has vanished," and an unresolved
`%key%` visible on screen is itself the diagnostic signal — it says the
extension's own table is incomplete, where a blank field would say nothing
at all.
**Approved**: pending

**Decision**: The default (`package.nls.json`) table's entries stay in the
merged result even when a more specific table for the same locale is also
present; only overlapping keys are overridden.
**Rationale**: A translation is nearly always less complete than the
English it was made from. Replacing the default table outright, rather than
merging under it, would turn every key the translation omits back into a
visible placeholder — "worse than not translating at all".
**Approved**: pending

**Decision**: When the merged table is empty, `localize` returns the input
`Data` unchanged rather than parsing and re-serializing it.
**Rationale**: Most extensions ship no translations at all, and the source's
doc comment states they "should not pay for a round-trip — nor risk one": a re-serialized document is not byte-identical to what came
in (key order and number formatting can change), so skipping the round-trip
entirely is also what keeps an untranslated manifest's bytes exactly as its
author wrote them.
**Approved**: pending

**Decision**: `substituting` maps only a JSON object's values, never its
keys.
**Rationale**: A key is a name the host matches on elsewhere — a command
id, a setting id, a language id. Substituting a key that happened to look
like a placeholder would make that name resolve to a word nothing else in
the host uses, silently breaking the match.
**Approved**: pending

**Decision**: Table filenames are matched against the names on disk without
regard to case.
**Rationale**: Real extensions on the registry are inconsistent about
casing — `package.nls.pt-BR.json` and `package.nls.zh-CN.json` both ship
with exactly that capitalization — and a locale-derived name is not a
promise about the file's actual case either, so an exact-case match would
silently miss real tables.
**Approved**: pending

**Decision**: A string is a placeholder reference only when its *entire*
content is one `%key%` token; a percent sign anywhere else in a string never
triggers a lookup.
**Rationale**: The source's own doc comment gives the counter-example this
guards against — "Uses 50% of one core" is prose, not a lookup of `of one
core, at most" … "Uses 50`, and this is the same rule VS Code itself applies.
**Approved**: pending

