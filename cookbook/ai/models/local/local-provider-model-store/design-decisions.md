
**Decision**: `fetchModels` strips at most one trailing `/` from `baseURL`
before appending `/models`, while `LocalModelServer.nativeTagsURL(baseURL:)`
(used by `fetchSizes`) strips every trailing slash and a trailing `/v1` in a
loop.
**Rationale**: Not stated in a source comment; this is a design fact rather
than a documented rationale. The practical effect is that a `baseURL` with
more than one trailing slash produces a well-formed native tags URL via
`fetchSizes` but a request with an embedded double slash via `fetchModels`,
which typically 404s and folds into the ordinary failure path rather than
crashing.
**Approved**: pending

**Decision**: `fetchModelInfo` awaits the catalog description, the rank, and
(conditionally) the ollama.com page strictly in sequence, never concurrently.
**Rationale**: Per the doc comment, "The catalog and rank awaits come FIRST
so a chooser's N per-model tasks all join the same live round of each before
fanning out to N page fetches" — the sequencing exists to line up with
`ModelCatalogStore.catalog()`'s and `ArtificialAnalysisStore`'s own
in-flight-task coalescing (see their respective sources), not to slow this
call down; the page fetch runs last because it has no such coalescing and is
the one call unique to each model.
**Approved**: pending

**Decision**: The description and page-stats caches are keyed by model id
alone (global), while the models, sizes, and metadata caches are keyed by
`baseURL` (or `baseURL` plus model id).
**Rationale**: Per the doc comment on `descriptionCache`, "Remote models
only ever get catalog text... Keyed by model name alone, not by server" — a
model's prose description and community popularity are properties of the
model itself, not of which server happens to be hosting it, so two servers
exposing the same model id intentionally share one cached description and
one cached stats entry.
**Approved**: pending

**Decision**: `fetchModels`/`fetchSizes`/`fetchMetadata` provide no locality
guard of their own — nothing stops a caller from invoking them with a
non-loopback `baseURL`.
**Rationale**: `isLocal(baseURL:)` exists specifically as the caller-facing
decision point (as `ModelChooserViewController` uses it before choosing
between this store and the remote descriptor catalog); `fetchModels` in
particular is a generic OpenAI-compatible `/models` listing with no
inherent local-only assumption, so baking a loopback check into it would
narrow a function that is otherwise reusable.
**Approved**: pending

**Decision**: Concurrent fetches for one key are not coalesced.
**Rationale**: Duplicate concurrent fetches for the same base URL (or base URL and model) each hit the server and the last write wins; closing the gap takes either an explicit acceptance of that cost or an in-flight-request cache keyed by base URL and model, mirroring the in-flight pattern used elsewhere in this family.
**Approved**: pending

