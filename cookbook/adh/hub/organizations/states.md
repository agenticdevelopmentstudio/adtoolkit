
Not applicable — this is a data-access client, not a visual component. Its observable "states" are
the ordinary async-operation states a caller already handles generically: in-flight (an awaited
asynchronous call), succeeded, and failed (a thrown HTTP error or plain error).

