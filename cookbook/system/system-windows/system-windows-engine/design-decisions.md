
**Decision**: Enumerate with the CoreGraphics window list and manipulate through Accessibility.
**Rationale**: Per the `SystemWindowManager` doc comment, the window list needs no permission and gives ids and PIDs, while move, resize and focus need Accessibility; the split keeps listing available to hosts without trust.
**Approved**: pending

**Decision**: Bridge a window id to an `AXUIElement` by PID plus a weighted title/position/size score, with title weighted 10 over geometry 5 and 3 and score 0 rejected.
**Rationale**: `AXUIElement` has no constructor from a CGWindowID; per the `bestMatch` comment a title match must dominate a geometry match, and two windows sharing both title and frame are inherently ambiguous, so the first wins.
**Approved**: pending

**Decision**: Geometry comparisons use a tolerance of strictly less than 2 points.
**Rationale**: The source's comments cite rounding differences between CoreGraphics bounds and AX geometry.
**Approved**: pending

**Decision**: Backfill empty titles through Accessibility, batched once per PID, taking a single-window app's title regardless of frame and refusing ambiguous frame matches.
**Rationale**: The window list omits titles without Screen Recording permission; per the `axTitle(forFrame:in:)` comment, an empty title is better than the wrong window's, and the single-window rule is what gives minimized windows a title.
**Approved**: pending

**Decision**: `focus` unparks a window by fixing only X, and visibility is tested on X alone.
**Rationale**: Parking moves windows far left while keeping Y; per the `isOnScreenHorizontally` comment, testing X avoids comparing CoreGraphics top-left Y with AppKit bottom-left screen Y.
**Approved**: pending

**Decision**: The engine is permission-agnostic; `SystemAccessibilityPermission` is separate and `request()` passes the prompt option as a string literal.
**Rationale**: Per its doc comment the UI decides when to check and prompt, and the SDK's `kAXTrustedCheckOptionPrompt` global is not concurrency-safe to reference under strict concurrency.
**Approved**: pending

**Decision**: `windowInfo(from:)` is shared by enumeration and the helper's lookup.
**Rationale**: Per its doc comment the AX path previously hardcoded the main display; one parser keeps fields and `display` identical on both paths.
**Approved**: pending

**Decision**: The window-created handler captures its baseline immediately, scoped to the owning PID, and waits 0.5 s; app launch waits 1.0 s.
**Rationale**: Per the `handleWindowCreated` comment, reading the baseline inside the delayed block races a synchronous destroy handler's refresh (TOCTOU) and would hide the new window; the delays let titles and windows settle.
**Approved**: pending

**Decision**: The observer is `@unchecked Sendable` with main-run-loop confinement and passes itself to AX callbacks as an unretained refcon.
**Rationale**: `AXObserverCreate` needs a C function pointer; confinement to the main run loop, documented on the type, is what makes the unchecked conformance sound, and `deinit` stops observation before the refcon could dangle.
**Approved**: pending

**Decision**: A failed unpark during focus is ignored and focus reports success.
**Rationale**: It stands today because the unpark result is discarded. Closing it needs the window manager owner to decide whether that failure throws the attribute-set-failed error, and a test.
**Approved**: pending

**Decision**: Observer registration failures are ignored; an app can be counted as monitored while reporting no events.
**Rationale**: It stands today because registration result codes are not examined. Closing it needs the owner to choose which registration errors are logged or surfaced, and a test with a failing registration.
**Approved**: pending

