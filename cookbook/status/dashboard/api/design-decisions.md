
**Decision**: `useStatusApi()` falls back to a single module-level
`defaultClient` singleton, built once at import time with no `basePath` or
`fetch` override, shared by every caller that has no ancestor
`StatusApiProvider`. (React/Web implementation.)
**Rationale**: matches the source directly — `const defaultClient =
createStatusApiClient();` is declared at module scope, and the doc comment on
`useStatusApi` states it returns "the same-origin default when no provider is
mounted."
**Approved**: pending.

**Decision**: mounting a bare `<StatusApiProvider>` with no `client` or
`basePath` prop builds a brand-new `StatusApiClient` (via `useMemo`) rather
than reusing the module's `defaultClient`; it behaves identically (same
default `basePath`, same global `fetch`) but is a distinct object reference.
(React/Web implementation.)
**Rationale**: `useMemo(() => client ?? createStatusApiClient({basePath}),
[client, basePath])` always calls `createStatusApiClient` when `client` is
falsy — it never falls back to the outer `defaultClient` constant, even
though the two clients are behaviorally interchangeable.
**Approved**: pending.

**Decision**: `EndpointWriteFields` is derived from `EndpointView`
(`Partial<Omit<EndpointView, "id" | "siteId">>`) instead of being hand-listed.
(React/Web implementation.)
**Rationale**: the inline comment states this directly: "Exactly EndpointView's
writable fields (derived — adding a column to EndpointView can't silently
drop it from create/update)." A new `EndpointView` field automatically
becomes writable through `createEndpoint`/`updateEndpoint` with no second
edit required.
**Approved**: pending.

**Decision**: `ignoreProjects` fans its per-project calls out with
`Promise.all` rather than a sequential loop or a concurrency-limited batch.
(React/Web implementation.)
**Rationale**: the doc comment states the unique `(platform, projectName)`
index makes a re-ignore idempotent, and that issuing the batch in parallel
makes ignoring a large batch cost one round-trip's latency rather than N; the
documented tradeoff is that one project's failure rejects the whole batch
immediately (`Promise.all` semantics) instead of reporting a per-project
partial result.
**Approved**: pending.

**Decision**: `peers.ts`'s `createPeer`/`updatePeer` serialize the caller's
object directly, while `monitored-sites.ts`'s group/site/endpoint functions
rebuild an explicit `fields` object before serializing. (React/Web
implementation.)
**Rationale**: this is a genuine divergence between the two sibling files,
not a typo — `monitored-sites.ts`'s comments explain its allow-list exists
because the hub's own generated API-type package does not match the status
backend's schema for these routes, a concern `peers.ts`'s simpler
`PeerWrite` shape does not have.
**Approved**: pending.

