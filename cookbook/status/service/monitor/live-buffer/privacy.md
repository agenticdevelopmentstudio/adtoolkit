
Not applicable: this file collects no data of its own. It holds, only in process memory and only until `CAP` eviction or a `clearDeployEvents()` call, the same `ProviderDeploy` values that `hooks.ts` already received over the webhook and already persisted to the database (per `pushDeployEvent`'s call site comment: "PERSIST the pushed state (not just the live buffer)"); it introduces no privacy surface of its own beyond that pass-through, and `ProviderDeploy` carries no token or credential field.

