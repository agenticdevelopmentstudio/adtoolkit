
**Decision**: Values are not validated or clamped when written through the holder.
**Rationale**: Clamping happens when the preferences snapshot reads the keys, so the range lives in one place; validating at the holder would need the settings pane to surface errors.
**Approved**: pending

