
**Decision**: Watch directories rather than individual files (OpenDocumentReloader).
**Rationale**: One filesystem-event stream serves every open document in a directory and survives file replacement (a common editor and version-control save pattern), which a per-file watch on some platforms would not.
**Approved**: pending

**Decision**: Distinguish "not yet known" from "known and empty" for semantic-token highlights.
**Rationale**: Lets a query correctly park and wait for the first fetch instead of momentarily painting a document as having no semantic highlights at all.
**Approved**: pending

**Decision**: Decline to map lexical token types (keyword, string, number, comment, operator) in SemanticTokenCaptureMapping.
**Rationale**: Keeps the existing tree-sitter highlighter the source of truth for those, avoiding two highlighters disagreeing about the same span.
**Approved**: pending

**Decision**: Apply completion's additional edits back-to-front, by descending start offset.
**Rationale**: Avoids recomputing every subsequent edit's range after each application, which would need the same information the server's own offsets already encode.
**Approved**: pending

**Decision**: Route every LSP capability check (hoverProvider, definitionProvider, the semantic-tokens full-request option) through the same bare-false-or-absent-means-unsupported rule.
**Rationale**: Keeps that judgment call in one place conceptually, even though each type implements its own copy, rather than risking the three checks drifting apart.
**Approved**: pending

**Decision**: Language-server request failures (completion, hover, jump-to-definition, semantic tokens) are caught and discarded with no log call; the hover controller and the jump-to-definition delegate do not conform to the shared logging protocol at all.
**Rationale**: The user-visible fallback (no completions, hover, jump target, or highlights) is the only signal today. Closing the gap means adding a log call to each catch, or a comment stating the silence is intentional.
**Approved**: pending

**Decision**: The reloader's catch around its injected file reader discards the read error without logging, unlike its dirty-conflict path, which logs.
**Rationale**: A transient read failure between the stat and the read is retried by the next event, so nothing is lost. Closing the gap means a log call on the caught path, or a comment explaining why none is needed.
**Approved**: pending

