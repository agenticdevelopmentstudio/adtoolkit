
**Decision**: `storageName(forKey:ofExtension:)` builds a slot per *extension*, `"extensions.<identifier>.<key>"`, rather than storing directly under the manifest's own dotted key.
**Rationale**: the source's own doc comment records that 389 keys in the corpus this classifier was built against are declared by more than one extension, 18 of them disagreeing on `(type, default)` — one flat slot provably cannot hold both, and withdrawal (removing one extension's settings without touching another's) has to be able to name exactly what one extension owns (`ContributedSettings.swift`).
**Approved**: pending

**Decision**: `ContributedSetting.key` is kept as the manifest's full dotted key, never a namespace-stripped leaf.
**Rationale**: the source's own doc comment reports that the first dotted segment matches the extension's own name only 84% of the time in the Open VSX corpus studied (`anysphere.pyright` declares `python.pythonPath`), so stripping a namespace would strip the one token that says which setting a row actually is — VS Code's own settings UI shows the full key for the same reason (`ContributedSettings.swift`).
**Approved**: pending

**Decision**: an `enum` option's `label` is looked up positionally against the *declared* member index, before any `null` member is dropped, rather than against the filtered `values` array's index.
**Rationale**: `enumItemLabels` is indexed against the manifest's own `enum` array (`ContributedSettings.swift`); reindexing after dropping `null` members would silently mislabel every option that follows a dropped `null`, so the code deliberately looks up `members[index]`'s label before filtering, not after.
**Approved**: pending

**Decision**: a default that is present but does not match any retained enum member (`enum-default-not-member`) is inserted as a brand-new option at index 0, rather than being discarded in favor of the first declared member.
**Rationale**: the source's own comment states the stored value has to be representable, or the popup would silently rewrite it out from under the user (`ContributedSettings.swift`); inventing an option that carries the actual stored value forward is the only way a `.choice` control can round-trip a value the schema's own `enum` does not otherwise allow.
**Approved**: pending

**Decision**: `"integer"` bounds round `minimum` up and `maximum` down (rounding inward) rather than to the nearest whole number, and the inversion check for `bounds-contradiction-dropped` runs *after* that rounding.
**Rationale**: the source's own comment explains that a bound which widened when rounded — e.g. a `minimum` of `0.5` rounding down to `0` — is the one direction that could let a clamp store a value the declared schema forbids; and because `minimum: 1.2, maximum: 1.8` does not invert as written but does invert to `2...1` after inward rounding, the contradiction check has to run on the rounded values, not the raw ones (`ContributedSettings.swift`).
**Approved**: pending

**Decision**: `"array"` and `"object"` types classify straight to `.json` with no `ContributedSettingNote`, while every other unrenderable path (`unrenderable-type-fallback`, `mixed-union-fallback`, the `nil`-default/no-type case in `no-type-inference`) records one.
**Rationale**: the source's own inline comment states this directly — `array`/`object` are "where a structured value is *supposed* to land, not a compromise" (`ContributedSettings.swift`) — distinguishing an intended destination for the JSON escape hatch from every case where the escape hatch is a fallback for something this classifier could not otherwise render.
**Approved**: pending

**Decision**: an out-of-`Int`-range `"integer"` `minimum`/`maximum` is silently dropped with no `ContributedSettingNote` (see `integer-bound-overflow` under Edge Cases), unlike every other bound anomaly this file handles.
**Rationale**: recorded here as observed technical debt affecting behavioral correctness, per Source Fidelity, rather than corrected — fixing it would mean adding a new `ContributedSettingNote.Kind` case, a decision outside this recipe's authority to make on the maintainer's behalf.
**Approved**: pending

