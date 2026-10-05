
Subsystem: the app's bundle identifier | Category: the manager's own logging category (see Platform Notes for the literal values the current implementation uses).

| Event | Level | Message |
|-------|-------|---------|
| Manager constructed and all handlers registered | info | A message confirming initialization and handler registration (see Platform Notes for the literal string the current implementation logs) |

No other event is logged: individual key-downs, out-of-range index no-ops and ignored add/remove results produce no log line from the manager (the model logs its own errors).

