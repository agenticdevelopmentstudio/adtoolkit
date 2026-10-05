
**Decision**: The grace period between the graceful and forceful termination signals (`terminationGrace`) is a hardcoded 2 seconds, not a parameter of the run-to-completion operation.
**Rationale**: (Swift implementation) Per the constant's own doc comment, a tool that ignores the graceful signal is exactly the tool this second step exists for, and "two seconds is long enough for an honest cleanup handler and short enough that nobody notices." The same fixed 2 seconds also bounds the post-exit drain wait (bounded-post-exit-drain-wait), so every run carries the same worst case: timeout plus up to two termination grace periods — a 120-second archive-expansion default plus this fixed grace is exactly the "124-second budget" its caller's own doc comment describes.
**Approved**: pending

**Decision**: The outcome's status is read from the process's own exit status only when a `didExit` flag is true; on a process that survived even the forceful termination signal, status is instead the never-exited sentinel (`-1`), and nothing further is attempted to force that process to exit.
**Rationale**: (Swift implementation) Per the doc comment on the guard, reading a still-running process's termination status is documented to raise an uncatchable Objective-C exception — reading it unconditionally would turn the one scenario this code exists to survive (a tool stuck in an uninterruptible kernel wait, such as a read against a wedged network mount) into a crash instead of a reported failure. This is fail-fast, not fail-crash, by explicit design; the source makes no further attempt to reap or signal a process that has already survived the forceful termination signal; such a process is left running, the process-level counterpart of abandoned-pipe-write-end.
**Approved**: pending

**Decision**: The outcome's timed-out and aborted markers are two distinct fields rather than one combined "was terminated early" flag.
**Rationale**: Per the doc comment on the aborted field, the two "report differently: a timeout says how long the caller waited, an abort says which limit the caller set was reached" — the archive-unpacking caller relies on exactly this distinction to choose between throwing an expansion-timed-out error and an expansion-too-large error, two errors with different messages and different remediation for a user.
**Approved**: pending

**Decision**: The post-exit wait for each stream's drain-completion signal is bounded to the termination grace period rather than left unbounded.
**Rationale**: (Swift implementation) Per the comment at the wait site, both write ends are ordinarily already closed by the time this code runs, so the wait is "on an end-of-file that has already been posted" and the bound exists only "in case a grandchild inherited one of them." The source accepts a small, fixed risk of returning slightly truncated output in that specific, named case rather than risk the run-to-completion operation itself hanging on a drain that has nothing left to signal it (see abandoned-pipe-write-end above).
**Approved**: pending

