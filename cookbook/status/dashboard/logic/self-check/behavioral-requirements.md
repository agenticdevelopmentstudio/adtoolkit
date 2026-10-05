
**Data shape**

- **view-shape**: The self-check view MUST carry exactly four fields: `missingEnv` (a list of strings), `missingEnvError` (boolean), `issues` (a list of checks) and `hasError` (boolean).
- **issues-are-source-checks**: Each entry of `issues` MUST be the original check object from the report's `checks`, not a copy or projection.

**Null result**

- **undefined-input-null**: The derivation function MUST return null when its input report is absent (the loading state, per the test "returns null when data is undefined (loading)").
- **nothing-to-show-null**: The derivation function MUST return null when, after filtering, `missingEnv` is empty and `issues` is empty.
- **non-null-when-content**: The derivation function MUST return a self-check view whenever `missingEnv` or `issues` is non-empty.

**Missing-env classification**

- **missing-env-check-selection**: A check MUST count as a missing-env check exactly when its `missingEnv` is present and has length greater than zero; an absent or empty `missingEnv` MUST NOT count.
- **missing-env-regardless-of-state**: A missing-env check MUST contribute its variable names whatever its `state` is, including `"ok"`.
- **missing-env-flatten**: `missingEnv` MUST contain every variable name from every missing-env check.
- **missing-env-dedup**: `missingEnv` MUST contain each variable name at most once.
- **missing-env-order**: `missingEnv` MUST keep first-occurrence order: checks in the report's order, then names in each check's `missingEnv` order.
- **missing-env-error-flag**: `missingEnvError` MUST be `true` exactly when at least one missing-env check has a `state` of `"error"`.
- **missing-env-warn-not-error**: A missing-env check with a `state` of `"warn"` MUST NOT set `missingEnvError`; the doc comment says a "merely-recoverable missing env (a 'warn') keeps the bar amber so it doesn't cry wolf".

**Issue selection**

- **issues-non-ok**: `issues` MUST include only checks whose `state` is not `"ok"`.
- **issues-exclude-cron**: `issues` MUST exclude any check whose `id` is `"cron"` (the internal check, "wallboard noise").
- **issues-exclude-missing-env**: `issues` MUST exclude every missing-env check, so a check is never shown in both the env chip and an issue chip.
- **issues-exclude-correlated**: `issues` MUST exclude any check whose `correlated` is truthy, because the backend collapses those into its single Connectivity check.
- **issues-order**: `issues` MUST keep the order of the report's checks.
- **issues-ignore-ok-flag**: Issue selection MUST read `state`, not the boolean `ok` field; a check with `ok: false` and `state: "ok"` MUST NOT be an issue.

**Severity**

- **has-error-missing-env**: `hasError` MUST be `true` when `missingEnvError` is `true`.
- **has-error-issue**: `hasError` MUST be `true` when any entry in `issues` has a `state` of `"error"`.
- **has-error-otherwise-false**: `hasError` MUST be `false` in every other case; the source comment says severity "follows actual check state — never forced red just because a var is unset".
- **excluded-errors-do-not-escalate**: An errored check that is excluded from `issues` (a `cron` check or a `correlated` check) MUST NOT set `hasError`.

**Execution and side effects**

- **pure-synchronous**: The derivation function MUST be pure and synchronous: same input, same output, no I/O, no network, no storage, no logging.
- **no-input-mutation**: The derivation function MUST NOT modify its input report, the report's `checks`, or any check; it builds new arrays by filtering and flattening.
- **no-validation**: The derivation function MUST NOT validate its input at runtime; an absent-or-present report is the caller's precondition, so a defined report is assumed to carry a `checks` list.
- **thread-model**: The derivation function MUST run synchronously to completion on the caller's thread, leaving no interleaving to order.

