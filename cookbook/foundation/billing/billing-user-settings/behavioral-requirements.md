
- **eight-settings**: The holder MUST expose exactly eight settings: `idleCutoffMinutes` (int), `granularity` (string), `roundingMinutes` (int), `roundingMode` (string), `defaultRateCents` (int), `currency` (string), `manualTimerCapHours` (int), `trackUnassigned` (bool).
- **keys-from-app**: Each setting MUST be stored under the matching key of the injected key set.
- **defaults-shared**: Each setting's default MUST be the shared billing default: idle cutoff 15, granularity `day`, rounding 15 minutes, mode `up`, rate 0 cents, currency `USD`, manual cap 8 hours, track-unassigned true.
- **rate-integer-cents**: The default rate MUST be integer cents per hour, never a floating-point value.
- **granularity-groups-entries-only**: `granularity` (`day` or `run`) MUST NOT change what is derived or how segments are stored, which is always whole; it only decides how the rollup groups segments into entries on later passes, so it can be switched at any time.
- **idle-cutoff-affects-derivation**: `idleCutoffMinutes` MUST be the one setting that changes what gets derived: a gap longer than it ends a run.
- **manual-cap-flags**: A manual timer running longer than `manualTimerCapHours` MUST be flagged, never truncated.
- **main-thread**: The holder MUST be used from the main thread only.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

