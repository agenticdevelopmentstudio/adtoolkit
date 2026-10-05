
**Decision**: Duplicate the backend's normalize and validate rules in the board, not share a module.
**Rationale**: The module doc comment says the board "is a separate Next app with its own build, so it cannot import the backend's module". Duplicating moves feedback earlier (the dirty check, and an inline sentence instead of a 400), while the backend stays the authority on every write.
**Approved**: pending

**Decision**: Make `normalizePeerBaseUrl` total, falling back to trim plus trailing-slash strip.
**Rationale**: The editor normalizes on every keystroke, "long before what is typed is a URL at all", so throwing or returning a sentinel would break the dirty check while the user types.
**Approved**: pending

**Decision**: Let WHATWG `URL` parsing do the canonical folding (case, default port) instead of hand-written rules.
**Rationale**: The inline comment says this "is what keeps `https://Lewis.example.com:443/` from becoming a second peer row". The backend's unique index on `base_url` is byte-exact, so every variation that names the same monitor has to fold to one string.
**Approved**: pending

**Decision**: Mirror only normalize and validate. Leave out the self-peer and duplicate checks.
**Rationale**: Those checks need server state (`config.publicBaseUrl`, the store's unique index), which the board does not hold. The backend reports those conflicts in its responses.
**Approved**: pending

