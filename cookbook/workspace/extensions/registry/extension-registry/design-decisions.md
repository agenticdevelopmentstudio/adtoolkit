
**Decision**: `searchPaths` is a caller-injected `[URL]` rather than a value `ExtensionRegistry` derives itself from a well-known location.
**Rationale**: The real search paths live behind `AppStorageLocation`, which sits in `apple-database`, a tier `ExtensionRegistry` cannot import without creating an upward dependency from a lower tier. The caller resolves the real paths and passes them in, the same pattern `AIPluginManager`'s test-only initializer already uses — see the `ai-plugin-runtime-ai-plugin-kit-ai-plugin-manager` recipe.
**Approved**: pending

**Decision**: `contributionsObservers` is a list of `(token, handler)` pairs rather than the single callback slot it replaced.
**Rationale**: More than one caller needs to react to a contribution change — the document layout has to widen before a contributed view can be placed, and an extension host has to reconcile separately — and a single slot meant whichever subscriber registered second silently un-wired the first. A prior workaround, where each subscriber read the slot and chained through it, was correct only as long as every subscriber remembered to chain, and failed silently the first time one did not.
**Approved**: pending

**Decision**: `loadAll()` withdraws every currently loaded extension's contributions from every registered point before rebuilding state, even for an extension that will be reapplied unchanged in the same pass.
**Rationale**: Clearing only the `extensions`/`failures` arrays without withdrawing first would leave every contribution point holding a duplicate application while the registry's own bookkeeping reported it once, and a single later `withdraw` call would then leave one copy behind. Withdraw-before-rebuild keeps the registry and every contribution point's state from ever disagreeing about how many times something was applied.
**Approved**: pending

**Decision**: `establishedIdentifiers` is computed on every access from `extensions`, `failures`, and `scanReadEverything`, rather than stored as a separately maintained third property.
**Rationale**: Deriving it guarantees it cannot drift out of step with the two arrays it is built from. `scanReadEverything` captures the one fact the arrays alone cannot express — a directory or search path the scan never got far enough to name leaves no trace in either array — so "every failure is nameable" is not by itself evidence the scan was whole.
**Approved**: pending

**Decision**: A directory caught mid-install or mid-update, with no `package.json` on disk yet, is treated identically to an ordinary non-extension directory: silently absent from both `extensions` and `failures`, with the scan still reporting itself complete.
**Rationale**: The alternative — treating any manifest-less directory as unnameable — makes the scan permanently incomplete on any search path holding one stray non-extension folder (a `.DS_Store` sibling, a README), which disables orphan pruning for every user, always. A rare, transient, largely self-healing loss (the extension's themes return on the next successful load) is accepted as the better trade against a certain, permanent one.
**Approved**: pending

**Decision**: `SemanticVersion` parses only `major[.minor[.patch]]` with no pre-release or build-metadata grammar, and `VSCodeEngineRange` is a direct port of VS Code's own `extensionValidator.ts` rather than an npm-semver-range reading of `engines.vscode`.
**Rationale**: `engines.vscode` looks like an npm semver range and is not one; an npm reading rejects roughly a quarter of real-world extensions VS Code itself runs, per the source's own cited Open VSX survey. A caret range on this grammar clears must-equal flags rather than computing a ceiling, and a sub-1.0.0 requirement is treated as compatible with 1.x except at an exact match — both intentionally surprising relative to npm semantics, and both load-bearing for extension compatibility.
**Approved**: pending

