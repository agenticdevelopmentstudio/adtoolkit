
- **Undefined report**: the input report is absent while the fetch is loading. The derivation function MUST return `null` (vector 001).
- **Empty checks list**: the report's `checks` is an empty list. Both lists are empty, so the function MUST return `null`.
- **Empty `missingEnv` list**: a check with `missingEnv: []` MUST be treated as having no missing env and MAY appear in `issues` if its state is not `"ok"` (vector 008).
- **Missing env on an ok check**: a check with `state: "ok"` and a non-empty `missingEnv` MUST still produce a non-null view with that name in `missingEnv` (vector 009).
- **Duplicate names within one check**: a check with `missingEnv: ["A", "A"]` MUST yield `["A"]`, because deduplication covers the whole flattened list.
- **Correlated check that also lists missing env**: it MUST contribute its names to `missingEnv`, since missing-env selection does not look at `correlated`.
- **Errored cron or correlated check alone**: MUST produce `null` and MUST NOT turn the bar red (vector 010).
- **`missingEnvError` implies non-null**: `missingEnvError` can only be `true` when `missingEnv` is non-empty, so a returned view with `missingEnvError: true` MUST have at least one name.
- **Malformed report**: a defined report without a `checks` list, or a `missingEnv` that is not a list, violates the typed precondition; the function performs no runtime check and a missing `checks` would raise a runtime error to the caller (see Platform Notes). This is a documented precondition (no-validation), not a handled path.
- **Network failure, timeout, offline**: not applicable to this function; it does no I/O. Fetch failures belong to [the integrations state](adtoolkit://cookbook/status/dashboard/state/integrations), which passes an absent report or the last good report.
- **Concurrent calls**: not applicable; the function is pure and synchronous, so concurrent callers (the banner and the dashboard pill) always get the same result for the same report.

