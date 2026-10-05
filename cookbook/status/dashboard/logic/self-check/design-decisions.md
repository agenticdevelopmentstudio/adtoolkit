
**Decision**: Return `null` rather than an empty view when there is nothing to show.
**Rationale**: The doc comment states the bar "can render exactly when `computeSelfCheck(...) !== null`", giving the banner and the dashboard pill one visibility test.
**Approved**: pending

**Decision**: Severity follows each check's own `state`; an unset variable alone never forces red.
**Rationale**: The source comment "never forced red just because a var is unset" and the `SelfCheckView` doc say a recoverable missing env stays amber "so it doesn't cry wolf"; only an error-state check (for example one where the account could not auto-discover) goes red.
**Approved**: pending

**Decision**: Exclude the `cron` check, missing-env checks and `correlated` checks from `issues`.
**Rationale**: Per the `issues` doc comment, missing-env checks are already shown in the env chip, `cron` is "wallboard noise", and correlated provider failures are "collapsed into the backend's single Connectivity chip". The consequence, stated as excluded-errors-do-not-escalate, is that an errored excluded check cannot turn the bar red.
**Approved**: pending

**Decision**: Keep the filtering in a pure module separate from the component.
**Rationale**: The doc comment says the rules are "slightly fiddly" and are "unit-tested without a DOM"; `Dashboard.tsx` reuses the same function so its pill count matches the bar.
**Approved**: pending

