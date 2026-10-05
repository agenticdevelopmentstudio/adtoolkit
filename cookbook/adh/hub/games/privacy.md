
- **Data collected**: Game/definition/effect/mapping catalog metadata only
  — slugs, names, descriptions, engine identifiers and configuration,
  status/character-name/event-log settings, effect triggers and deltas,
  and mapping edges. The module's own header comment states this
  deliberately excludes the `game` schema's eight other, player-state
  tables, which have no operator read path through this client.
- **Storage**: This module holds no cache of its own; every call is a live
  round trip through `authedJson`/`authedRequest`.
- **Transmission**: Every request travels through the injected
  `@agentic-toolkit/auth` Bearer-token client (`authedJson`/
  `authedRequest`, re-exported via `./http`); this module itself attaches
  no credentials and reads no cookies (see `auth-client`).
- **Retention**: Not applicable — this module retains nothing between
  calls; it has no cache with a lifetime to document.

