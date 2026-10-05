
Environment Filter is client-side state that holds which deployment environments the status dashboard's Overview shows. The selectable environments are the constant `ENVIRONMENTS` (`["production", "staging", "testing"]`). The selection starts with every environment selected (no filter), is hydrated once from persistent per-browser storage after the initial state settles so the pre-hydration render and first paint match, and every toggle is written back to storage under the key `"adh-env-filter"` so the choice survives reloads. The Overview treats "every environment selected" (`envs.size === all.length`) as unfiltered.

Use it wherever a view needs a persisted, per-browser multi-select over the fixed environment list. It holds no visual surface of its own.

