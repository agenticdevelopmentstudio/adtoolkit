
- **Decision**: let the app's native `.openapi()`-generated paths and schemas win over every hand-written module's entries on any path or schema-name collision.
  **Rationale**: `build.ts`'s own comment states this directly — the auto-generated entries win on any path/schema key collision because they are the source of truth for the routes they cover; the five natively-registered routes are already correctly documented by the framework from the route's own zod schemas, so a hand-written module documenting the same key would only be a manually-maintained duplicate that could drift.
  **Approved**: pending
- **Decision**: document `/live/check`'s `503` with a literal success-shaped schema (`{ ok: false, ran: false, reason: 'no scheduler' }`) instead of routing it through the shared `errors()` helper and the `Error` schema every other failure code in this component uses.
  **Rationale**: not stated in a source comment beyond the route's own summary ("503 without a scheduler"); the response body this route actually returns on that path is the same `{ ok, ran, reason }` shape as its `200`, just with fixed `false`/`no scheduler` values, so describing it with the generic `Error` schema would document a body the handler never sends — recorded here as the one deliberate divergence from this component's own `errors()` convention, not an oversight.
  **Approved**: pending
- **Decision**: document `DELETE /tokens/{id}` with a bare `204` (`description: 'Revoked'`, no body) while every other row-deleting mutation in this surface (`config.ts`'s five `DELETE` operations, `users.ts`'s `DELETE /users/{id}`) documents `200` with the shared `okFlag` (`{ ok: boolean }`) body.
  **Rationale**: not explained in a source comment; the two shapes are not interchangeable for a generated client — one has a body to parse, the other must not — so a port MUST preserve each operation's documented status code and body shape exactly rather than assuming one uniform delete convention across this surface.
  **Approved**: pending

