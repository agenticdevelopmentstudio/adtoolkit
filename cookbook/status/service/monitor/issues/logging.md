
This module logs warnings and errors with a literal `[ledger]` prefix, not a structured logger with its own subsystem/category object.

| Event | Level | Message |
|-------|-------|---------|
| A shadow row retired for a target that already had a canonical open row | warn | `[ledger] retired duplicate open issue #<id> for <target> — uniq_open_issue_per_target should have prevented it` |
| A storage write (insert, update, or resolve) threw for one target | error | `[ledger] write failed for <target> — skipped, the next cycle re-derives it: <error message>` |

A successful open, update, or recovered/unmonitored resolve produces no log output at all, at any level.

