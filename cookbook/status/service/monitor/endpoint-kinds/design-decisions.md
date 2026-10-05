
- **Decision**: re-export `NON_DEPLOY_KINDS` from `@agentic-toolkit/deploy-platform/engine` rather than declaring a separate literal set in this file.
  **Rationale**: stated directly in the source comment — "they used to be three separate literal Sets, here, in the browser, and in the engine" and could "come to disagree" over which kinds are non-deploy-backed, most concretely `dns`. Re-exporting one shared object removes the possibility of the three call sites drifting apart on that specific question.
  **Approved**: pending
- **Decision**: derive `EndpointKind` from `ENDPOINT_KINDS` via `(typeof ENDPOINT_KINDS)[number]` instead of a hand-written union type declared independently of the array.
  **Rationale**: not spelled out in an inline comment, but demonstrated as deliberate by the type declaration itself — deriving the type from the runtime array is the idiom that keeps a literal-union type and its backing array from drifting apart, the identical failure mode the module's other comment describes for the pre-re-export `NON_DEPLOY_KINDS` history.
  **Approved**: pending
- **Decision**: give `ENDPOINT_KINDS` an `as const` assertion without also calling `Object.freeze` on the resulting array.
  **Rationale**: not stated in the source; recorded here as a fact of the code per this recipe's authoring rules, not a defended choice — the immutability this file relies on is a compile-time-only guarantee (`compile-time-immutability`), so a caller that bypasses the type system can still mutate the shared array at runtime, for every subsequent importer of the same module instance.
  **Approved**: pending

