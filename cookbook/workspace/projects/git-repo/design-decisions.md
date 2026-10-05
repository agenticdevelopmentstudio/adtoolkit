
**Decision**: `GitRepo`'s `Equatable` conformance is the compiler-synthesized
one over every stored property, including `firstSeen`, `lastSeen`, and
`lastOpened` — not a hand-written conformance that compares `id` alone.
**Rationale**: The type's header doc comment states "the identity is the
`id`, not the path" to justify using a `UUID` as the primary key rather than
the path, but that statement is about which field a *database row* is keyed
on; it does not extend to `==`. Because `firstSeen`/`lastSeen` default to
`Date()` at construction time, two values built independently for what a
caller considers "the same" repository will almost always compare unequal —
a quirk a port must preserve deliberately rather than "fix" into
identity-based equality, or callers that rely on `==` (e.g. `Set` membership,
diffing) will behave differently than the source.
**Approved**: pending

**Decision**: `ProjectScanSummary` declares an explicit, parameterless
`public init() {}` even though every stored property already has a default
value.
**Rationale**: Swift only synthesizes a memberwise (or default,
parameterless) initializer at the same access level as the type when the
type is not `public`; for a `public` struct, the compiler-synthesized
initializer is `internal`, so a caller outside this module could not
construct a `ProjectScanSummary` at all without this explicit `public init()`
— the same reason `GitRepo.init` and `ScannedGitRepo.init` are both written out explicitly rather than relied upon as
synthesized.
**Approved**: pending

**Decision**: `ProjectScanSummary.found` sums `added + moved + unchanged +
skipped` but excludes `removed`.
**Rationale**: The doc comment on `found` calls it "every project in the
registry once the scan has been applied" — a repository the scan
determined to be `removed` is, by definition, no longer in the registry, so
counting it in `found` would overstate what is actually there. `summaryText`
still names removals in its parts list because reporting "what changed"
and reporting "what remains" are different facts, matching this file's
general pattern of not conflating adjacent-but-distinct counts (see also
`unchanged` never appearing in `summaryText`'s parts, and `skipped` field
name vs. its "not scanned" wording).
**Approved**: pending

**Decision**: `ScannedGitRepo` is a distinct type from `GitRepo` rather than
`GitRepo` with an optional `id`, and its `remote` parameter has no default
(unlike `GitRepo.remote`, which defaults to `nil`).
**Rationale**: The doc comment states directly that "a scan result has no
identity yet: deciding whether it is a new repository, a moved one, or one
already known is the reconciler's job" — giving `ScannedGitRepo`
an `id` field (even an optional one) would let a caller construct a
scan result that already claims an identity, which is exactly the ambiguity
this type is designed to prevent until reconciliation happens elsewhere.
Requiring `remote` explicitly (rather than defaulting it to `nil` the way
`GitRepo` does) keeps every scan-result construction site stating plainly
whether a remote was found, since omitting the argument by habit is easy to
do at a `GitRepo` call site but is not possible here.
**Approved**: pending

