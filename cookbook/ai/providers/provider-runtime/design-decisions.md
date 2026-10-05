
**Decision**: Every network-backed store (`ArtificialAnalysisStore.allRanks()`, `ModelCatalogStore.catalog()`) always performs a live fetch and never serves from a timed cache; concurrent callers instead join one shared, in-flight `Task`.
**Rationale**: the source doc comments state this directly — a chooser refreshing many models at once must trigger one network round, not one per model, while the very next burst after that round still gets fresh data rather than stale cached data.
**Approved**: pending

**Decision**: Catalog/rank matching (`ModelCatalogStore.bestMatchKey`) is prefix-anchored on the model's normalized base name and restricted by parameter-size tag, rather than a fuzzy or substring match.
**Rationale**: the source doc comment states the reason directly — neither OpenRouter nor models.dev knows about community fine-tunes, so an "uncensored" fine-tune must never inherit its base model's blurb; conservative matching trades recall for correctness.
**Approved**: pending

**Decision**: `ClaudeCLI.run` drains stdout/stderr concurrently with the exit wait, and performs the wait itself off the Swift concurrency cooperative thread pool.
**Rationale**: the source doc comment gives both reasons — a child that writes past the ~64KB pipe buffer would deadlock against a synchronous wait, and `Process.waitUntilExit()` blocks its calling thread, which would otherwise pin a concurrency worker for the duration of the call.
**Approved**: pending

**Decision**: `ClaudeCLI.run` marks its child process's environment with `AGENTIC_TOOLKIT_HEADLESS=1`.
**Rationale**: the source doc comment explains this lets an inherited session-tracking hook (named as "stenographer") distinguish a programmatic/headless invocation from a real interactive Claude Code session and exclude it from recording.
**Approved**: pending

**Decision**: `ModelCatalogStore.description(for:)` checks the adh provider-template catalog before OpenRouter or models.dev.
**Rationale**: the source doc comment states the adh catalog's descriptions are operator-authored and curated, and therefore authoritative where present, with OpenRouter/models.dev retained only as the fallback pair.
**Approved**: pending

**Decision**: CLI reply parsing is an unfinished stub: the CLI provider's reply is never extracted and always reads as the empty-response fallback.
**Rationale**: The CLI branch of reply parsing is a placeholder in the source (a `// todo: fix this` comment followed by a fall-through), so only the HTTP providers' response shapes are parsed. Closing it takes defining the CLI response shape and extracting the reply text from it, with a test vector for that shape.
**Approved**: pending

**Decision**: Custom and OpenAI-compatible endpoint base URLs are not scheme-validated.
**Rationale**: The builder and the two fetching stores take the caller's base URL verbatim, so a plain-http endpoint sends the bearer key in cleartext; the four built-in provider URLs are fixed HTTPS literals and are unaffected. Closing it would take rejecting or warning on non-https schemes (allowing loopback for local servers such as Ollama) at the point the URL is accepted.
**Approved**: pending

