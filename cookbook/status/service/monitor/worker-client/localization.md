
This component has no user-visible UI, but it does build four hardcoded English error messages that propagate to its caller (and from there, potentially, to an operator-facing log or alert). It routes through no localization mechanism.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `monitor cycle exceeded <cycleTimeoutMs>ms — worker terminated; next cycle respawns it` | Rejection when a cycle run's timeout elapses with no reply (cycle-timeout-rejection-message) |
| n/a | `<error>` (the reply's error value, verbatim) | Rejection when a reply arrives with an ok flag of `false` and an error string (reply-not-ok-rejects-with-message) |
| n/a | `monitor cycle failed` | Rejection when a reply arrives with an ok flag of `false` and no error string (reply-not-ok-rejects-with-message) |
| n/a | `monitor worker crashed: <err.message>` | Rejection of every pending call on the worker's error event (worker-error-rejects-all-pending) |
| n/a | `monitor worker exited (<code>)` | Rejection of every pending call on the worker's exit event (worker-exit-rejects-all-pending) |

