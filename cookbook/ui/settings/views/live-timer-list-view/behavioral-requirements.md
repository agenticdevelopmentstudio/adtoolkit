
- **shows-empty-message**: The empty message MUST be visible when no timers are set and hidden otherwise.
- **one-row-per-timer**: The list MUST show one row per timer, in the given order.
- **keeps-rows-by-id**: A reload MUST keep the row of every timer still listed and update it rather than rebuild it.
- **updates-in-place-when-ids-match**: When the ids are unchanged, only rows whose model changed MUST be updated.
- **only-manual-can-stop**: The stop button MUST be visible only on a hand-started timer's row.
- **stop-reports-the-id**: Stopping a row MUST report that timer's id through the list's stop callback.
- **ticks-only-while-seen**: The ticker MUST run only while at least one timer exists and the window is visible.
- **catches-up-when-seen**: When the list becomes seen, the clocks MUST be refreshed immediately and not wait for the next interval.
- **watches-occlusion**: The list MUST re-evaluate visibility when its window's occlusion changes, as well as when it moves into a window.
- **no-window-means-not-seen**: With no window the list MUST treat itself as not seen.
- **tick-notifies-the-host**: After every tick the list MUST call the host's tick callback so other on-screen elements can count the same seconds.
- **clock-and-tooltip-propagate**: The injected clock and the automatic-origin tooltip MUST apply to existing and new rows.
- **visibility-is-injectable**: The visibility check MUST be injectable so a test can cover a window that is open but covered.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

