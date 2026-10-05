
This is a shared source of the two facts an inference guard and a fit
policy need about the host machine: total physical RAM and the OS's own
memory-pressure signal. An injectable monitoring interface is the seam a
guard's constructor depends on by default; the concrete implementation
reads physical RAM once at construction and latches the OS's
memory-pressure notifications behind a lock-guarded field, so any caller
can read the current pressure level from any thread without touching the
underlying notification mechanism or its queue itself.

