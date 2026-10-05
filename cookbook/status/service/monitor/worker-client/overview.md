
The worker client is the scheduler's handle to the monitor's background
worker. It keeps the scheduler itself (single-flight guarding, watchdog,
cadence, staleness reporting) off the worker's own thread of execution, and
turns each monitor cycle into one request/reply round trip to that worker.
Output the cycle produces still reaches the same process's logs, because the
worker shares its host's standard output.

It is deliberately self-healing: a cycle that exceeds its configured timeout
has its worker terminated, and the next cycle spawns a fresh one — a wedged
provider chain recovers in-process rather than through the surrounding
supervisor's own restart, which remains the backstop of last resort. An
unexpected worker crash likewise fails the in-flight cycle and lazily
respawns on the next call. The client accepts its database connection value
only as an opaque type it never inspects, specifically so it never has to
name a concrete connection type of its own.

