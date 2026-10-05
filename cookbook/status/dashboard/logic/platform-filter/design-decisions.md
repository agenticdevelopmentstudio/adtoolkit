
**Decision**: Always offer every known platform, regardless of which endpoints exist.
**Rationale**: The header comment records the regression: a data-driven list hid `railway` whenever no monitored site used it, which is the steady state because railway hosts backends rather than the monitored frontends (pf-001).
**Approved**: pending

**Decision**: Show unknown platform values that are actually present, after the known ones.
**Rationale**: The doc comment calls these "legacy/odd data"; listing them keeps such endpoints filterable without adding them to the canonical list (pf-005).
**Approved**: pending

**Decision**: Show the no-platform row only when some endpoint is unwired, but always include its key in the "all" set.
**Rationale**: The doc comment says the bucket "is meaningful as a filter only when such sites exist", while `allPlatformKeys` includes it so the "all" reset "can never omit one" and an unwired site that appears later is visible by default (pf-003, pf-007).
**Approved**: pending

**Decision**: Use a string sentinel `"__none__"` for the null platform.
**Rationale**: The selection is a `Set<string>`, so `null` needs a string stand-in to be a selectable key; the doc comment says this keeps an unwired site "a selectable filter row rather than being silently dropped from 'all'".
**Approved**: pending

**Decision**: Leave unknown platform keys out of `allPlatformKeys()`.
**Rationale**: `allPlatformKeys` takes no endpoint data, so it can only name the known platforms and the sentinel. The consequence is that endpoints with an unknown platform are hidden under the default selection until selected (pf-014).
**Approved**: pending

