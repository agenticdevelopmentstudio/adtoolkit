
Not applicable — this is domain logic, not a visual component. Its only
observable "states" are the ordinary async-operation states a caller
already handles generically: pending (an awaited call), succeeded, and
failed (a thrown error carrying the backend's message).

