
Subsystem: the host app's bundle identifier (via the shared logging
protocol's default) | Category: the logging component's own name

| Event | Level | Message |
|-------|-------|---------|
| Diagnostic/document forwarding failure while the session is not running | debug | A not-running operation failure |
| Any other diagnostic/document forwarding failure | error | The default forwarding-failure path |
| Channel forwarding-task failure | error | The transport channel's stream-end handling |
| A second concurrent observation of a live session's state | fault | The refusal to observe a session a second time |
| Session start/stop/teardown failures | error | The session's failure-diagnosis pipeline |

The diagnostics store and the sync coordinator conform to no logging
protocol and emit no log calls of their own — a plain fact about this
component, not a gap; their failure signal is a ledger write (the
divergence ledger) or the observable state they publish, not a log line.

