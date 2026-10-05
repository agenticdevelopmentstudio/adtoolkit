
A main-thread holder of the eight billing settings: idle cutoff minutes, granularity, rounding minutes, rounding mode, default rate in cents, currency, manual timer cap in hours, and track-unassigned. Each is a live user setting stored under a key from one app's billing settings key set, so the app decides only the key prefix (and therefore the namespace in the settings table). Defaults come from the shared billing defaults, the same numbers the daemon falls back to, so the settings pane, the wire and the deriver share one set of values.

