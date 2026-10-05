
- **Empty board**: `problems`, `activity` and `monitoredTargets` MAY each be empty arrays; the type allows it and `indicatorFor([])` yields the operational indicator (test vector board-types-004). MUST.
- **No observations**: `dataAsOfMs` MUST be `null` when the board rests on no observations; consumers MUST treat that as distinct from a fresh board (`useBoard` folds it into a `no-data` reason). MUST.
- **Unknown source at runtime**: A server that emits an `IssueSource` the client does not know is not caught by this module (no runtime validation); per `issue-sources.ts` the client then renders `undefined` in the filter and badge. The parity test is the guard against this, at compile time only. MUST (fact of the contract).
- **Out-of-vocabulary state**: `Problem.state` is a free `string`; a value outside the documented list MUST still typecheck and be carried through unchanged. MUST.
- **Shared timestamp**: A deployment's build and deploy rows share one `createdAtMs`; paging MUST use the `(atMs, id)` pair so neither row is repeated or skipped across pages. MUST.
- **Corrected deploy metadata**: When `deployments.created_at`, `project_name` or `branch` is corrected after first render, the row `id` MUST NOT change. MUST.
- **Exhausted history**: `nextCursor: null` MUST mean no older page exists. MUST.
- **Drift under test runs**: `pnpm test` transpiles without typechecking, so drift is caught only by `pnpm typecheck` in this package and by the dashboard host's `web` typecheck, which names the parity test under `files`. SHOULD run both in CI; a test-only run cannot detect drift.
- **Malformed payload**: A response that does not match `Board` is not detected by this module; behavior is owned by the consumer that parses it (see [useBoard](adtoolkit://cookbook/status/dashboard/state/board)). MUST (fact of the contract).
- **Concurrency, network, offline, cancellation, timeouts**: Not applicable; the module has no runtime behavior.

