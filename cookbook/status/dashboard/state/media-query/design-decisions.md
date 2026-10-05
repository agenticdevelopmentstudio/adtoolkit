
**Decision**: Return `false` until the subscription is established, rather than reading the media query immediately.

**Rationale**: The contract states the server "can't measure the viewport"; a fixed `false` keeps the server render and the first client render identical, which avoids a hydration mismatch. This rationale applies to the web platform, where a server-rendering pass and a client paint must agree; a platform with no such split has no counterpart requirement.

**Approved**: pending

---

**Decision**: Call the environment's media-query facility with no existence guard.

**Rationale**: Media Query targets environments where the facility always exists; test environments that lack it (jsdom) stub it, as `OverviewTab.dom.test.tsx` does, instead of Media Query carrying a fallback.

**Approved**: pending

---

**Decision**: Re-seed the value from the facility's match result on every query change.

**Rationale**: A change listener fires only on transitions, so without the immediate read the value would stay at the previous query's result until the viewport next crossed the new query's boundary.

**Approved**: pending

