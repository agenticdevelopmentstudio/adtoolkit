
**Decision**: Idle time is never part of a span.
**Rationale**: A span closes at the previous stamp because the idle stretch is how the stop is detected; counting it would overstate worked time by up to one idle gap per run.
**Approved**: pending

**Decision**: Lead-in, open-run handling and the cutoff stay with the caller.
**Rationale**: Billing, a monitor and a report each choose different policy; keeping the algorithms policy-free lets one copy serve them all.
**Approved**: pending

