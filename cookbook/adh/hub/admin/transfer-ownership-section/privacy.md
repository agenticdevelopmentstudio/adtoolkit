
- **Data collected**: The typed confirmation text, which the user re-enters as a copy of the
  caller-supplied `entityLabel`; no other input is captured by this component itself.
- **Storage**: None — the chosen target, preview result, typed value, busy state, and error all
  live in transient, in-memory state and are cleared on reset or on unmount; nothing is written to
  persistent storage.
- **Transmission**: The component transmits nothing itself; it invokes the caller-supplied
  preflight/confirm operations with the chosen target, and any network transmission those
  operations perform is outside this component.
- **Retention**: None beyond the component's own lifetime, or until reset runs — see Storage
  above.

