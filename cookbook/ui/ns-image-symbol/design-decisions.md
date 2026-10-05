
**Decision**: A missing symbol yields a blank 16 by 16 template image instead of an absent value, a trap or a visible placeholder glyph.
**Rationale**: The source's own comment explains that `NSImage(systemSymbolName:)` answers nil for a misspelled name or a symbol this macOS does not ship, and a force-unwrap turns that into a crash in whatever view built the button; a blank image lets the control lay out and keep its description.
**Approved**: pending

**Decision**: The fallback is silent — no log line, assertion or diagnostic marks that a symbol was missing.
**Rationale**: The source returns the blank image without any signal, so a typo in a symbol name shows up only as an empty control; adding a debug-build diagnostic would close that gap but is not in the source today.
**Approved**: pending

