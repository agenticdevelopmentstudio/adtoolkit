
**Data shape**

- **endpoint-like-shape**: the endpoint-like shape MUST carry the engine's
  own fields — a text `kind`, a nullable text `platform`, a nullable text
  `deployProject`, and an optional boolean `ignoreProjectWarning` — plus an
  optional boolean `isActive`.
- **is-active-optional**: `isActive` MUST be optional, so that a caller
  whose own shape does not carry the field (a leaner projection, a test
  fixture) still satisfies the endpoint-like shape.

**The opt-out fold**

- **opt-out-ignore-flag**: the opt-out fold MUST return `true` when
  `ignoreProjectWarning === true`.
- **opt-out-paused**: the opt-out fold MUST return `true` when
  `isActive === false`.
- **opt-out-strict-false**: the opt-out fold MUST treat only an explicit
  `false` in `isActive` as paused; an absent or unset `isActive` MUST NOT
  count as an opt-out.
- **opt-out-strict-true**: the opt-out fold MUST treat only an explicit
  `true` in `ignoreProjectWarning` as an opt-out; `false` or absent MUST NOT
  count.
- **opt-out-default**: the opt-out fold MUST return `false` in every case
  not covered by opt-out-ignore-flag or opt-out-paused.
- **opt-out-minimal-input**: the opt-out fold MUST read only
  `ignoreProjectWarning` and `isActive`; its input needs only these two
  fields.

**The status operation**

- **status-folds-before-classify**: the status operation MUST classify a
  copy of the endpoint whose `ignoreProjectWarning` is replaced by the
  opt-out fold's result, with every other field passed through unchanged.
- **status-no-mutation**: the status operation MUST NOT modify the caller's
  endpoint object; the fold is applied to a shallow copy.
- **status-delegates-to-engine**: the status operation MUST return exactly
  what the shared engine's own classifier returns for the folded copy; the
  result is one of `configured`, `unconfigured`, or `ignored`.
- **status-infra-kind**: an endpoint whose `kind` is one of the engine's
  non-deploy kinds (`health`, `custom`, `dns`) MUST classify as
  `configured`, whatever its wiring or opt-out fields.
- **status-wired**: a deploy-backed endpoint with a truthy `platform` and a
  truthy `deployProject` MUST classify as `configured`.
- **status-paused-wired-stays-configured**: a wired deploy-backed endpoint
  with `isActive: false` MUST classify as `configured`, not `ignored`; the
  opt-out is consulted only in the engine's unwired branch, so pausing a
  site does not un-configure it.
- **status-unwired-opted-out**: a deploy-backed endpoint missing its
  platform or deploy project MUST classify as `ignored` when the opt-out
  fold is `true`.
- **status-unwired-not-opted-out**: a deploy-backed endpoint missing its
  platform or deploy project MUST classify as `unconfigured` when the
  opt-out fold is `false`.
- **status-empty-string-unwired**: an empty-string `platform` or
  `deployProject` MUST count as missing, because the engine tests them by
  truthiness.

**The unconfigured predicate**

- **unconfigured-derived**: the unconfigured predicate MUST return `true`
  exactly when the status operation returns `"unconfigured"`.
- **unconfigured-uses-wrapper**: the unconfigured predicate MUST derive from
  this module's own status operation, not from the engine's own unconfigured
  predicate, so that the two predicates agree about a paused endpoint.

**Execution and side effects**

- **pure-synchronous**: every export MUST be a pure, synchronous function:
  same input, same output, no I/O, no network, no storage, no logging.
- **no-validation**: the functions MUST NOT validate their input at
  runtime; the endpoint-like shape is the caller's precondition, and the
  engine applies the same assumption.
- **no-errors**: every export MUST return without throwing for any input
  that satisfies the endpoint-like shape; there is no error return path.
- **server-twin**: the opt-out fold MUST give the same answer as the
  backend's own fold of the same name; the name is shared so a divergence
  shows up as two answers to one question. The backend's behavior is owned
  by its own route, outside this module.

