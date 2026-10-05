
- **Data collected**: None of its own — this view holds only the
  appearance value (two colors, two booleans) and a weak view reference
  in memory. The terminal session's actual command/output content is
  entirely the underlying terminal engine's responsibility, outside this
  file.
- **Storage**: N/A — no persistence call appears in source; state lives
  only in memory for the view's lifetime.
- **Transmission**: N/A — this view performs no network or IPC calls.
- **Retention**: N/A — nothing is retained beyond the view's lifetime.

