
- **shows-title-and-subtitle**: The row MUST show the model's title and subtitle.
- **hides-empty-subtitle**: The subtitle line MUST be hidden when the subtitle is absent or empty.
- **elapsed-is-a-clock**: The elapsed time MUST be shown as a clock of hours, minutes and seconds counted from the model's start time.
- **elapsed-never-negative**: If the injected clock is earlier than the start time, the row MUST show zero elapsed, never a negative time.
- **clock-is-injectable**: The row MUST take its notion of now from an injectable clock so tests can state the time.
- **clock-uses-fixed-width-digits**: The clock MUST use a monospaced style so the row does not shift sideways as the seconds roll over.
- **update-swaps-the-model**: Updating MUST replace the shown model and recompute the clock from the new start time.
- **stop-reports-the-id**: Pressing stop MUST report the model's id through the stop callback.
- **origin-dot-shows-origin**: The origin dot MUST be filled for a hand-started run and hollow for an automatic one.
- **origin-tooltips-are-the-callers**: The tooltips for the two origins MUST default to Started by hand and Started automatically and MUST be settable, taking effect on the shown row at once.
- **title-gives-way-to-clock**: When space is short the title and subtitle MUST truncate before the clock and stop button do.
- **controls-carry-identifiers**: The stop button and the clock MUST carry identifiers built from the model's id.
- **ticker-ticks-while-started**: A ticker MUST call its tick callback once per interval from start until stop.
- **ticker-start-is-idempotent**: Starting a running ticker MUST change nothing and MUST NOT double its rate.
- **ticker-stop-is-safe**: Stopping a ticker that is not running MUST be harmless.
- **ticker-runs-during-tracking**: The ticker MUST keep ticking while a menu is open or a list is scrolling.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

