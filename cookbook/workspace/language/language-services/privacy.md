
- **Data collected**: the text document holds exactly the caller-supplied text for the file at its URI — in practice, the full content of whatever file a user has open in an editor pane, plus that file's path (as a `DocumentUri`). Neither the text document, the document store, nor the save scheduler inspects, parses, or interprets that content beyond UTF-16 offset bookkeeping.
- **Storage**: held only in memory (the document's own text, and the document store's open-documents map) for as long as the document stays open; the save scheduler writes it back to disk only through the caller-injected persistence operation, which this component does not implement — persistence, encryption, and location are entirely that operation's responsibility.
- **Transmission**: this component performs no network call of its own.
- **Retention**: a document's text and dirty state persist in memory until closing its URI removes the last open reference to it; a save that keeps failing leaves its bytes only in memory, retried in the background with no time limit, until it succeeds or is explicitly cancelled.

