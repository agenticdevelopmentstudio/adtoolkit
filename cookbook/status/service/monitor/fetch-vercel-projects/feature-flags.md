
Not applicable: this file consults no feature-flag system; whether it runs at all is gated entirely by the presence of `VERCEL_API_TOKEN` (noop-missing-token) and the shared cooldown registry (cooldown-gate-on-entry), and its `metaOnly` field is a per-call request-shape switch supplied directly by the caller, not a flag-service lookup.

