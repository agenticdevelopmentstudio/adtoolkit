
This module provides two interchangeable adapters behind a shared telemetry-source contract: an object exposing exactly one operation, `get`, that takes the injected API client and resolves to a telemetry snapshot. Each reads one snapshot (fields `generatedAt`, `errors`, `analytics`) from the dashboard backend through the caller's injected client, so the consumer never knows whether the data is live or persisted.

- The **live source** reads `/telemetry`, where the backend polls the configured error-tracking and analytics providers and returns the data directly. Its authoring note states that no database sits anywhere on this path, so a database outage cannot affect the dashboard's errors and analytics. It is the source wired today.
- The **persisted source** reads the persisted store via `/errors` and `/analytics` in parallel and assembles the snapshot itself. It is documented as the target for reconnecting the persisted backend later.

The composition root holds both adapters and exports the active one; switching backends is a one-line change there. The only consumer is the telemetry state, which calls the active source's `get` operation as its read function.

