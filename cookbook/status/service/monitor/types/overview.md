
This module declares the shared record vocabulary for the monitor's read
routes: eleven record shapes plus three shared status vocabularies (health
status, overall status, and deploy status), with no behavior and no side
effect of its own. The service status record is the base per-endpoint health
row (extended elsewhere by the live service record); the daily uptime entry,
per-service uptime summary, and uptime response bundle the uptime route's
daily rollups; the deployment record is the shape a deploy row becomes for
the board (produced elsewhere, outside this recipe); the history check entry
and history response declare the history route's per-check series; and the
check state, integration check entry, and integrations response declare the
integrations self-check report. This recipe specifies each record's
field-level shape and the invariants a producer or consumer of a value of
that shape MUST honor — not the route, mapper, or self-check logic that
builds or delivers one, which is each related recipe's own concern.

