
**Decision**: When the board is operational, print "N/N endpoints healthy" only when every endpoint is healthy, and otherwise print "N endpoints monitored".
**Rationale**: The source comment explains that under an operational board, a non-healthy endpoint is a transient blip (degraded within the window) or an unprobed one, not an incident. A fraction such as "4/5 healthy" beside "ALL SYSTEMS OPERATIONAL" would read as a contradiction.
**Approved**: pending

**Decision**: The breakdown accounts for every problem, and unmapped status words fall through verbatim.
**Rationale**: The doc comment requires the parts to "sum to the indicator count". A status word added elsewhere without a table entry still shows up as `{n} {word}` rather than silently disappearing from the caption.
**Approved**: pending

**Decision**: Some status words are relabelled rather than echoed: `building` becomes "stuck build" and `deployment failed` becomes "stale deploy".
**Rationale**: The source comment says a building row "only reaches Problems when stuck", so "stuck" names the actual condition. The "stale deploy" wording for `deployment failed` is taken directly from `SUBLABEL_PHRASE` and distinguishes it from the `deploy failed` phrase.
**Approved**: pending

**Decision**: One function serves every status caption surface.
**Rationale**: The doc comment says it is shared by the mobile hero and the desktop top-bar pill, so the two surfaces cannot word the same board differently. In the current tree only `OverviewTab` (feeding `BigIndicator`) calls it.
**Approved**: pending

