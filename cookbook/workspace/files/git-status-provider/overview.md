
This component asks a git client for one repository's working-tree status
and broadcasts the result to every registered observer, on the UI thread.
One provider serves every pane watching a checkout, so a refresh answers
"everyone's badges," not just whoever triggered it; overlapping refresh
calls coalesce into at most one queued follow-up run rather than one process
per call. A failed or cancelled check is reported as an explicit
"unavailable" result rather than an empty status, because an empty status
and "we could not ask" are different facts a consumer must not confuse. A
companion status-to-color mapping is what the badges this provider's status
feeds actually paint with: it gives every status value a fixed hue,
represented once per color type the platform's UI layer(s) require, so that
whichever one draws the badge, red still means deleted.

