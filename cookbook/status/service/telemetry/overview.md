
Status Server Telemetry is a trigger-agnostic collection abstraction that decouples data fetching from persistence. It composes a source (Fetcher) with a sink (Store) for each data stream (errors, analytics), allowing the same collection logic to be driven by scheduled cycles, manual refreshes, or webhooks. Failed provider polls never overwrite good data, and a GlitchTip platform-health observation records whether the errors provider is configured and reachable, so downstream error rules freeze rather than falsely recover during an outage. PostHog gets no platform-health observation.

