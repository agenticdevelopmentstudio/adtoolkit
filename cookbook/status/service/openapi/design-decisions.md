
- **Decision**: let an auto-generated (`.openapi()`-registered) path or component-schema entry win over a hand-written one of the same key, rather than the reverse.
  **Rationale**: traced directly to `build.ts`'s own doc comment — "The auto-generated entries WIN on any path/schema key collision (they are the source of truth for the routes they cover)"; a native `.openapi()` route already carries its own zod-validated request/response types, which are authoritative for that route, so letting a hand-written module's static fragment for the same key shadow it would document the less accurate of the two.
  **Approved**: pending
- **Decision**: force `bearerAuth`'s security scheme to the literal `{ type: 'http', scheme: 'bearer' }` unconditionally, after spreading whatever `getOpenAPI31Document` produced for `securitySchemes`.
  **Rationale**: not stated in source as prose; this is a plain observation of the assignment order in `build.ts` (spread `doc.components.securitySchemes` first, then reassign `bearerAuth` on top), recorded as a fact about the code's actual behavior — every documented operation using `BEARER` security is guaranteed to resolve to this one bearer scheme shape, with no auto-generated `bearerAuth` entry able to diverge from it.
  **Approved**: pending
- **Decision**: reuse one identical `errorResponse` object (and `BEARER`, `okFlag`) as a shared constant across every call site, instead of a per-call factory that would produce an independent copy each time.
  **Rationale**: traced to `shared.ts`'s own comment on `errors` — "One place to define what a documented error entry is, instead of repeating `: errorResponse`"; every documented 4xx/5xx entry across all fourteen path modules intentionally shares the identical reference, trading per-call-site independence for a single edit point if the error envelope's documented shape ever changes.
  **Approved**: pending
- **Decision**: swallow a `zodJson` conversion failure into a generic `{ type: 'object', additionalProperties: true }` fallback, with no logging and no re-throw.
  **Rationale**: traced to `zodJson`'s own doc comment — the fallback exists only for a zod type JSON Schema cannot represent (its cited example is a raw `z.date()`), and every actual route schema in this codebase is a plain JSON shape, so the fallback path is documented as "defensive only," not an expected runtime occurrence needing a signal.
  **Approved**: pending

