
A manual timer is a billing segment with origin `manual` and an empty end, the same row shape a derived run uses, so it rolls up, assigns and displays through one code path. The one invariant is that at most one manual timer runs: starting a timer closes any other running timer at the same instant, inside one transaction, because two running timers would bill the same wall-clock minute twice. Derived runs belong to the derivation pass and are never closed by hand. A timer that runs longer than a cap is flagged, never stopped or truncated.

