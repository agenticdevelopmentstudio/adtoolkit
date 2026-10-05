
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | — | When false, history is discarded and `loadOlder` returns without fetching. Required; caller decides whether the age-out filter is active. |
| `live` | a list of activity rows | — | The current live window's oldest-first rows from the board's activity feed (or equivalent). Required; this logic uses it to derive the cursor and detect shed rows. |
| Page size | number | 300 | Hard-coded page size; every request asks for 300 rows. The server clamps to the same value. |
| Page timeout | milliseconds | 20000 | Hard-coded timeout; every fetch aborts if it does not settle within 20 seconds. |
| Auto-page fetch budget | number | 5 | Hard-coded auto-fetch budget; `loadOlder` returns without fetching once this many fetches have started since the last `resetAutoBudget` call. |

