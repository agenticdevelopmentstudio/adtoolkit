
The guard is the memory guard the local-model chat pathway consults before
dispatching a chat request to a loopback ("local") model server. Given a
model name and base URL, its verdict operation asks the model catalog for
the model's on-disk size, asks the injected memory monitor for the machine's
physical RAM and latched memory-pressure level, and returns a verdict
(allow, block-with-reason, or defer-with-reason) from the model-fit policy.
Independently of that verdict, an exclusive-run operation serializes local
inference process-wide behind a single mutex, so two host features that each
trigger a local model load (e.g. summaries and oversight) cannot do so at
once; the mutex is a FIFO queue of parked acquirers with direct-handoff
release, and each exclusive run is bounded by a wall-clock deadline (600s by
default) after which the operation is cancelled and the guard reports a
deferred refusal. The guard's refusal error type (blocked/deferred) is a
distinct error type from the daemon's own completion error type: a guard
refusal is "terminal for this attempt" and must never be reinterpreted as a
transport failure eligible for the CLI fallback path.

