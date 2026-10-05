
**Decision**: The key uses the raw platform string, not the canonical platform.
**Rationale**: The source comment states the raw platform is "the same value carried in DeployProject and persisted as an ignored-project row", so keys built on the client match persisted rows byte for byte. `PlatformProjects.tsx` canonicalizes the platform only when it builds the request body, after de-duplication by raw key.
**Approved**: pending

**Decision**: One module owns key formatting instead of each caller writing the template literal.
**Rationale**: The source comment warns that "a separator/field drift would otherwise silently make every ignore a no-op" between the review modal and the provider.
**Approved**: pending

**Decision**: De-duplication keeps the first-seen entry and does not pick production explicitly.
**Rationale**: The source relies on the backend ordering a project's environments production-first, so the first entry already carries the production representative domain; this keeps the helper generic and free of environment knowledge.
**Approved**: pending

**Decision**: The separator is a bare `|` with no escaping.
**Rationale**: Platform identifiers are a fixed backend set that does not contain `|`, so plain concatenation is unambiguous in practice; the collision case is recorded under Edge Cases.
**Approved**: pending

