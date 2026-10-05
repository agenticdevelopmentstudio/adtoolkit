
Not applicable: this file consults no feature-flag system; whether it runs at all is gated entirely by the presence of `RAILWAY_API_TOKEN` (noop-missing-token) and the shared cooldown registry (cooldown-gate-on-entry), both already documented under Behavioral Requirements and Configuration, not a flag-service lookup.

