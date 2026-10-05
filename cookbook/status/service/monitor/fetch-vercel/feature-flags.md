
Not applicable: this file consults no feature-flag system; whether each function performs a network call at all is gated entirely by the presence of `VERCEL_API_TOKEN` (noop-missing-token, fetch-deploy-error-noop-token, fetch-build-log-noop-token) and the shared cooldown registry (cooldown-gate-on-entry, fetch-deploy-error-cooldown, fetch-build-log-cooldown), both already documented under Behavioral Requirements, not a flag-service lookup.

