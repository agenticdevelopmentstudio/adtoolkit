
**Decision**: Use one shared slug function for both groups and sites.
**Rationale**: The doc comment calls it "The one shared slug form for groups and sites". Group defaults in `ConfigPanel.tsx` and host-derived site slugs in `EndpointsSection.tsx` therefore follow the same rules and cannot drift apart.
**Approved**: pending

**Decision**: Restrict the slug alphabet to ASCII `a`–`z`, `0`–`9` and `-`, with no transliteration.
**Rationale**: The replacement pattern keeps only ASCII alphanumerics, so every slug is URL- and identifier-safe without encoding. The cost is that non-Latin and accented names lose characters or become empty, which the function accepts rather than reports.
**Approved**: pending

**Decision**: Leave uniqueness to the backend.
**Rationale**: The function is pure and cannot see existing slugs. The status-server unique indexes on group and site slugs are the authority, so collisions surface as backend responses instead of being resolved on the client.
**Approved**: pending

