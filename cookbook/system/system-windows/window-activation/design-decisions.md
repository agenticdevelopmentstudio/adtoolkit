
**Decision**: Activation is a cascade of pluggable `WindowActivationStrategy` values run in order, stopping at the first success.
**Rationale**: Each terminal needs a different technique (AppleScript TTY lookup for iTerm2, accessibility title match for others, plain app activation as a last resort); the protocol's `appliesTo` gate keeps inapplicable strategies out of the log as FAILED lines, and callers can supply their own list.
**Approved**: pending

**Decision**: Verification after the cascade only checks that some window other than the host app is frontmost with a non-empty title, and the host app is reported under the fixed label `Sessions`.
**Rationale**: The harness was written for the Session Watcher's "Sessions" window; the check detects "focus left our app" rather than "the target is frontmost", which makes PASS a weak signal (see Edge Cases).
**Approved**: pending

**Decision**: Fixed blocking sleeps (0.15 s, 0.5 s, 1.0 s) sequence activation, verification and the next target.
**Rationale**: App activation and window raising complete asynchronously in the window server; the harness is documented to run on a background thread, so blocking sleeps are an accepted diagnostic-only cost.
**Approved**: pending

**Decision**: `ActivationTestLog` never truncates an existing file on append and silently drops a line it cannot write.
**Rationale**: The `appendToFile` doc comment prefers losing one line over risking truncation of the history; memory keeps every entry regardless.
**Approved**: pending

**Decision**: `RunningAppsProvider` abstracts `NSWorkspace` so strategies and the tester can run against a stubbed app list, while the terminal inventory always uses `KnownTerminals.all`.
**Rationale**: Testability of strategies was the goal of the abstraction; the inventory is diagnostic output and was not parameterized by catalog.
**Approved**: pending

**Decision**: The accessibility raise strategy reports success without checking its activate, raise and set-main results.
**Rationale**: It stands today because only the title match gates the return. Closing it needs a toolkit-owner decision on whether a failed raise returns false, and a test.
**Approved**: pending

**Decision**: The bring-to-front strategy reports success regardless of the activate result.
**Rationale**: It stands today because the activate result is not read. Closing it needs a toolkit-owner decision on whether that result gates the return value, and a test.
**Approved**: pending

**Decision**: Log file writes are not serialized with the in-memory buffer, so the file can diverge from the text.
**Rationale**: It stands today because only the in-memory append is queued. Closing it needs a toolkit-owner decision to move file writes onto the queue, and a concurrent-append test.
**Approved**: pending

