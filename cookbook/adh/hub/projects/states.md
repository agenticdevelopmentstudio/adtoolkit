
Not applicable — this is domain logic, not a visual component. Its
observable "states" are the ordinary asynchronous-operation states a caller
already handles generically: pending, succeeded, and failed (a thrown error
carrying a numeric status code), plus the live-wake subscription's own
connected/reconnecting/polling states, which are entirely owned by the
underlying connection helper and merely consumed here.

