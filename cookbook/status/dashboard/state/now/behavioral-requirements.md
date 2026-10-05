
- **signature**: Now MUST take one optional numeric input (the refresh interval in milliseconds) and MUST return a single number.
- **default-interval**: When the interval is omitted, the refresh interval MUST be 30,000 ms.
- **return-unit**: The returned value MUST be a millisecond Unix epoch timestamp representing the current wall-clock time.
- **mount-snapshot**: On first use, Now MUST return the current wall-clock time captured at that moment.
- **stable-between-ticks**: Repeated reads between ticks MUST return the same value as before; Now MUST NOT read the clock again except at the initial snapshot and at each scheduled refresh.
- **periodic-refresh**: Every `intervalMs` milliseconds after Now starts running, it MUST replace its stored value with a fresh wall-clock reading, which MUST notify the caller of the change.
- **no-immediate-refresh**: Now starting to run MUST NOT itself update the value; the first refresh happens one full `intervalMs` after it starts.
- **single-timer**: Now MUST keep at most one active interval timer per instance at any time.
- **interval-change-restart**: When the interval changes between uses, Now MUST clear the existing timer and start a new one with the new interval; the stored value MUST NOT be reset by the change.
- **unmount-cleanup**: When the caller stops using it, Now MUST clear its interval timer so no further updates are scheduled.
- **instance-independence**: Each use MUST own an independent clock and timer; two callers using Now are not synchronized and MAY return values that differ by up to one interval.
- **client-only**: Coarse Clock MUST run only in a live client execution context; it has no server-only or universal-rendering variant.
- **no-validation**: Now MUST pass the interval to the timer unchanged; it performs no range or type check of its own.
- **no-side-effects-beyond-timer**: Now MUST NOT perform network, storage, logging or other I/O; its only side effect is the interval timer.
- **concurrency**: All updates MUST run on a single execution thread via the timer callback and the caller's own update mechanism; there is no cross-thread access, so ordering between ticks and reads is determined by that thread's scheduling.

