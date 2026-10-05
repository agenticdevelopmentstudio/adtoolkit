
**Decision**: The Delete, Cancel and OK button titles are hardcoded English.
**Rationale**: The helpers predate the localization pass; closing the gap needs string keys and a bundle the caller can override.
**Approved**: pending

**Decision**: Confirmations with no window decline instead of proceeding.
**Rationale**: Declining is the safe answer for a destructive action when nothing can be shown; the cost is that headless callers never get to confirm.
**Approved**: pending

**Decision**: Escape is wired by an invisible zero-size button rather than by making Cancel the only key-equivalent holder.
**Rationale**: The destructive button must not be the default, and the alert's own Escape handling is not relied on; the hidden button keeps Escape working in both cases.
**Approved**: pending

