
A stateless function that converts raw tracked seconds into billed seconds by rounding to a whole number of minute increments. It is applied once, at entry level: rounding each segment and summing would bill five five-minute bursts as 75 minutes instead of 30. The rounding arithmetic belongs to the shared increment-rounding utility; this type only maps billing's two stored knobs (increment minutes and mode) onto it.

