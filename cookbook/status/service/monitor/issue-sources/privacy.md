
- **Data collected**: none of this file's own — it receives already-derived status values (`HealthStatus`, `DeployStatus`), an integration's already-configured `platform` string, and a caller-supplied set of Vercel project names as plain function arguments; it collects nothing itself.
- **Storage**: none. This file holds no state between calls and writes nothing; the consecutive-failure count `nextPlatformStreak` advances is persisted by its caller to `platform_health_state` (`libsql/stores/observation-store.ts`), external to this file.
- **Transmission**: none. This file performs no network or database call of its own.
- **Retention**: not applicable — this file holds no data across calls.

