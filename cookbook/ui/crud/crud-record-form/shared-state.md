
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `meta` (table metadata) | Caller | Field builder + payload builder | Down | Parameter |
| `initial` (existing row, optional) | Caller | Draft seed + create/edit mode | Down | Parameter |
| `draft` (text/boolean buffer) | The form | Per-column controls | Down | Local state + a field setter |
| field edits | Per-column controls | `draft` | Up | Change callback → the field setter |
| `busy` / `error` | Submission-state mechanism | Buttons (disabled/"Saving…") + inline error text | Down | Internal state |
| submit payload | The form (payload builder) | Caller's submit callback | Up | Callback (awaited) |
| cancel intent | Footer Cancel | Caller's cancel callback | Up | Callback |

