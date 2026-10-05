
**Decision**: Hydration deferred to `useEffect` despite initialization to default.

**Rationale**: Ensures SSR/first paint matches the default (preventing hydration mismatch warnings) and treats `localStorage` as an external store updated after render, not as derived state.

**Approved**: pending

---

**Decision**: Silently ignoring `localStorage` errors instead of propagating or logging them.

**Rationale**: `localStorage` is not guaranteed to be available (private browsing, quota exceeded); the hook falls back to the in-memory state, which is sufficient for correctness. No user-facing error is necessary because the feature (age-out) remains functional with the default.

**Approved**: pending

---

**Decision**: Key `"adh-healthy-ttl"` deliberately unchanged from the earlier "Healthy" feature.

**Rationale**: Renaming would reset every existing reader's choice to the default, breaking user preference persistence.

**Approved**: pending

