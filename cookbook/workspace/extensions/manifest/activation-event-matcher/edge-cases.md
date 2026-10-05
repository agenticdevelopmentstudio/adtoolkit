
- **Null/empty input**: an empty `activationEvents` array, or one containing
  only entries that fail to parse, yields an empty recognized-events list,
  eager activation false, and (per `empty-manifest-no-match`) no trigger
  matches. An entry that trims to the empty string, or a prefixed entry
  with an empty payload, is rejected rather than treated as a wildcard or
  an empty-string match (`empty-entry-rejection`, `empty-payload-rejection`).
- **Malformed glob syntax**: a `workspaceContains:` glob using a
  square-bracket character class or a leading exclamation-mark negation is
  rejected at parse time and recorded in the unsupported-patterns list; it
  never matches, and it never causes building the matcher to fail or throw
  (`glob-syntax-unsupported`, `glob-triage`).
- **Malformed engine range**: an `engines.vscode` string this component
  cannot parse (anything outside `*`, an optional `^`/`>=` prefix, and
  three numeric-or-`x` components) yields an empty implicitly-activating-
  commands set, never a crash or a missing matcher
  (`implicit-activation-unparseable-engine`).
- **Boundary values — implicit-activation floor**: an engine of exactly
  `"1.74.0"` or `"^1.74.0"` grants implicit activation; an engine one patch
  below the floor (`"^1.73.0"`, or any range whose minimum version is less
  than 1.74.0) does not; an unconstrained engine (`"*"`) grants it, because
  "no version claim" is treated as distinct from "a claim to predate 1.74"
  (`implicit-activation-floor`).
- **Boundary values — glob anchoring**: a pattern must consume the entire
  path at both ends; a pattern that matches a prefix or suffix of a path
  but not the whole of it does not match (`glob-anchoring`).
- **Concurrent access**: an activation event, an activation trigger, a
  workspace scan, and the activation event matcher are all immutable
  values with no mutable stored state reachable after construction, and
  glob matching builds its memoization tables as local state scoped to
  that one call rather than shared mutable state on the pattern — so
  matching MAY be called concurrently against the same matcher or the same
  glob pattern, with no synchronization required.
- **Error states**: not applicable — every operation in this component is a
  synchronous, non-throwing, pure computation over already-in-memory
  values; there is no I/O, so there is no error channel to define.
- **Offline/disconnected**: not applicable — this component performs no
  networking and touches no filesystem; a workspace scan's paths are
  supplied by the caller, who is responsible for the directory walk that
  produced them.
- **Unbounded input size**: checking a workspace-scanned trigger and
  matching a glob pattern define no timeout, cancellation, or size limit;
  matching runs synchronously to completion regardless of how many paths a
  workspace scan carries or how many backtracking tokens a pattern contains
  (mitigated for cost, not bounded for time, by `backtracking-memoization`).

