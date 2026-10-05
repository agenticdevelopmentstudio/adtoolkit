
Not applicable: `timeAgo` receives only a timestamp (`iso`) and a caller-supplied clock
reading (`nowMs`) as plain arguments — infrastructure event metadata, not end-user or
credential data — collects, stores, and transmits nothing of its own, and returns a
formatted string with no persistence.

