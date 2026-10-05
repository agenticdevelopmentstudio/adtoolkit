
- **snapshot-all-knobs**: `snapshot` MUST read idle cutoff (seconds), granularity, default rate (cents), currency, rounding minutes, rounding mode, manual timer cap (seconds) and track-unassigned in one call.
- **defaults-and-clamp**: Each missing or unparseable value MUST fall to the shared default, and each numeric value MUST be clamped to its shared limit (idle cutoff 1 to 480 minutes, rounding 1 to 240 minutes, rate 0 to 10,000,000 cents, manual cap 1 to 24 hours).
- **granularity-fallback**: An unrecognised granularity MUST fall back to `day`.
- **read-failure-throws**: A failure to read the settings table MUST throw; it MUST NOT silently fall back to defaults.
- **units**: The snapshot MUST hold the cutoff in seconds and the cap in seconds; `wireForm` MUST convert back to minutes and hours.
- **rollup-options**: `rollupOptions` MUST carry granularity, default rate and currency into the rollup.
- **apply-allow-list**: `apply` MUST write only keys that belong to the billing key set and ignore all others.
- **apply-transaction**: `apply` MUST write all keys and compute before and after snapshots inside one write transaction, so a failure leaves nothing half-applied and is thrown.
- **store-verbatim**: `apply` MUST store values verbatim and rely on clamping at read, so the range lives in one place.
- **cutoff-change-resets**: If the effective idle cutoff differs after the write, `apply` MUST reset the derivation state of every session with derived time.
- **apply-returns-snapshot**: `apply` MUST return the snapshot in force after the write.

