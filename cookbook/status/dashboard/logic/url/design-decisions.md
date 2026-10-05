
**Decision**: A parse failure returns the input unchanged instead of an empty string or `null`.
**Rationale**: The result is a display label. Handing back the raw string means a URL typed without a scheme (`example.com`) still shows something readable in `StatusMatrix`, `Dashboard` and the other row titles, and the `string` return type needs no null handling at call sites.
**Approved**: pending

**Decision**: The function returns WHATWG `host` (with a non-default port) rather than `hostname`.
**Rationale**: `host` keeps the port, so two endpoints on the same machine with different ports get different labels and different site names and slugs in `EndpointsSection`.
**Approved**: pending

**Decision**: A parsed URL with an empty host returns `""`, not the input.
**Rationale**: The function returns `new URL(url).host` verbatim whenever parsing succeeds and applies the fallback only to thrown errors. Callers that need a non-empty label add `|| url` themselves (caller-empty-fallback).
**Approved**: pending

