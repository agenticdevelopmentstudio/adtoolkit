
- **start-closes-others**: `start` MUST close every other running manual timer at the new timer's start instant and insert the new segment in one transaction; a failed insert MUST leave the previous timers running.
- **start-resolves-project**: When the request names no project and has a non-empty project root, `start` MUST resolve project and repo from the root and branch through the store's claim; when the request names a project it MUST be used unchanged.
- **start-shape**: The new segment MUST have a fresh id, an empty session id, origin `manual`, an empty end, zero seconds, the request's root, branch and note, the start instant `now`, and the current time zone identifier.
- **stop**: `stop(id)` MUST close the segment at `now` with seconds equal to the elapsed time and return the closed segment.
- **stop-unknown**: `stop` of an id that does not exist MUST throw `unknownTimer`.
- **stop-not-running**: `stop` of a segment that is already closed MUST throw `notRunning`.
- **stop-all-manual-only**: `stopAll` MUST close every running manual timer, MUST leave derived runs alone, and MUST return how many it closed.
- **running**: `running` MUST return every running segment of any origin.
- **flag-runaways**: `flagRunaways(capSeconds)` MUST add the flag `runaway` to every running manual timer whose elapsed time exceeds the cap, MUST NOT stop or truncate it, and MUST return how many it newly flagged.
- **cap-non-positive**: A cap of zero or less MUST flag nothing.
- **clock-injected**: Every operation MUST take `now` as a parameter defaulting to the current UTC time so it is testable.
- **errors-are-sentences**: Timer errors MUST present the shared refusal sentences for an unknown timer and a timer not running.

