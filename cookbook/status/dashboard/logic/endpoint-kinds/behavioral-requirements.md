
### ENDPOINT_KINDS

- **kinds-members**: `ENDPOINT_KINDS` MUST contain exactly the six strings `"http"`, `"frontend"`, `"admin"`, `"health"`, `"custom"` and `"dns"`.
- **kinds-order**: `ENDPOINT_KINDS` MUST list the kinds in the order `http`, `frontend`, `admin`, `health`, `custom`, `dns`. Consumers that render the list as a dropdown show it in this order, and a consumer that takes the first element as a default gets `"http"`.
- **kinds-readonly**: `ENDPOINT_KINDS` MUST be declared `as const`, so its type is a readonly tuple of literal strings. Any attempt to push to, splice or reassign an element MUST fail type-checking.
- **kinds-lowercase**: Every member MUST be a lowercase ASCII word with no whitespace. Matching against the list is exact and case-sensitive.

### EndpointKind

- **kind-type-derived**: `EndpointKind` MUST be derived from `ENDPOINT_KINDS` by indexed access (`(typeof ENDPOINT_KINDS)[number]`), so it is the union `"http" | "frontend" | "admin" | "health" | "custom" | "dns"`.
- **kind-type-single-source**: Adding or removing a member of `ENDPOINT_KINDS` MUST change `EndpointKind` with no second edit. The union is never written out by hand.

### isEndpointKind

- **guard-signature**: `isEndpointKind` MUST take one argument `k: string` and MUST return a `boolean` that the type system treats as the predicate `k is EndpointKind`.
- **guard-true**: `isEndpointKind` MUST return `true` when `k` is exactly equal (strict `===`, as `Array.prototype.includes` compares strings) to one of the six members.
- **guard-false**: `isEndpointKind` MUST return `false` for every other string, including the empty string, a member with different casing (`"HTTP"`), a member with surrounding whitespace (`" http"`), and kinds used by other vocabularies such as `"tcp"` or `"icmp"`.
- **guard-no-normalization**: `isEndpointKind` MUST NOT trim, lowercase or otherwise normalize `k` before comparing it.
- **guard-no-throw**: `isEndpointKind` MUST NOT throw for any string argument.
- **guard-no-callers**: No module in the repository calls this file's `isEndpointKind`. The status server validates with its own identically written `isEndpointKind` in `status-server/src/monitor/endpoint-kinds.ts`. A port MUST still provide the guard, because it is part of the exported contract.

### NON_DEPLOY_KINDS

- **non-deploy-reexport**: The module MUST re-export `NON_DEPLOY_KINDS` from `@agentic-toolkit/deploy-platform/engine` as the same object. It MUST NOT declare its own set. The authoring comment says it is "Re-exported (never restated)" so the warning badge and the engine's classification cannot disagree about `dns`.
- **non-deploy-members**: Through that re-export, `NON_DEPLOY_KINDS` MUST be a `ReadonlySet<string>` containing exactly `"health"`, `"custom"` and `"dns"`, as the engine declares it.
- **non-deploy-subset**: Every member of `NON_DEPLOY_KINDS` MUST also be a member of `ENDPOINT_KINDS`. The deploy-backed kinds are therefore `http`, `frontend` and `admin`, which the engine's `endpointNeedsWiring` returns `true` for.
- **non-deploy-ownership**: Which kinds are deploy-backed MUST be decided by the engine, not by this module. The authoring comment says this is "the CLASSIFIER's knowledge, not this list's". This module's consumers that need the classification (for example `config-status.ts`) call the engine's classifier directly.

### Purity and concurrency

- **pure-module**: The module MUST have no side effects on import and hold no mutable state. Its exports are a constant tuple, a type, a pure function and a re-exported constant.
- **single-threaded**: The module runs on the single JavaScript thread and holds no mutable state, so concurrent calls cannot interleave and it needs no ordering rule.

