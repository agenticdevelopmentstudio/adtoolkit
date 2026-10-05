
**Decision**: the save scheduler delegates all per-key debounce, retry, and backoff bookkeeping to a generic per-key debounce-and-retry helper (on Apple platforms, `KeyedDebouncer<DocumentUri>`) rather than implementing its own.
**Rationale**: per the Swift source's own doc comment, three prior copies of this exact pattern — a notes-saving scheduler, this component's own earlier shape, and a semantic-highlighting provider's one-shot variant — were "structurally identical and independently wrong in the same place": each removed a pending entry from its map before attempting the write and only logged on failure, so a write that hit a full disk or a revoked network volume silently lost the edit. Extracting the shared debounce-and-retry helper fixes that failure mode once for every caller instead of three times.
**Approved**: pending

**Decision**: opening a URI a second time ignores that call's text and language id, returning the already-open text document unchanged.
**Rationale**: the source's own doc comment states "the text already open is authoritative, not the text of a later open call" — favoring the in-memory buffer, which may already carry unsaved edits from one pane, over whatever a second opener happens to read from disk, rather than silently discarding the first pane's edits when a second pane opens the same file.
**Approved**: pending

**Decision**: the save scheduler marks a document clean only if its version is unchanged from the version captured immediately before the write began, rather than unconditionally after a successful write returns.
**Rationale**: the write runs asynchronously and can suspend, so the user can type between the snapshot and the write landing. Per the doc comment, marking clean unconditionally "would clear the dirty indicator over a buffer that is genuinely newer than the file"; declining does not lose the edit, because the text document's own change handler has already scheduled the next save for it. The cost is one extra debounce cycle in the rare case the user types during a write.
**Approved**: pending

**Decision**: the document store performs no coordination at all with the save scheduler — closing a URI neither flushes nor cancels any pending autosave for it.
**Rationale**: the two components hold no reference to each other anywhere in the given sources; each is independently injectable and independently testable. Wiring "close implies flush" is left to a caller — the sibling `file-editor-view` recipe documents its own call to flush a URI's pending save before discarding a pane's document — rather than being built into either lower-level component. Recorded here as an architectural boundary between "what is open" and "what is scheduled to be saved," not as a defect in either component.
**Approved**: pending

**Decision**: the URL-to-document-URI conversion returns the URL's absolute string form verbatim, with no normalization of symlinks, trailing slashes, or differing percent-encoding between two URLs that name the same file on disk.
**Rationale**: the extension's own doc comment states a narrower contract than full URL equivalence — it exists so "two independent call sites... agree on exactly this string for exactly the same file," i.e. so the *same* URL value converts consistently, not so that two *different* string representations of the same on-disk file converge to one `DocumentUri`. Any such normalization, where a caller needs it, happens at a different layer outside this component.
**Approved**: pending

