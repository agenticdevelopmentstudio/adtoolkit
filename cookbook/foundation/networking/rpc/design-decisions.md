
**Decision**: `MessageFramingDecoder`'s newline scan tracks a `scanCursor` that is shifted (not reset to `0`) every time completed frames are cut off the front of the buffer, so a subsequent `consume(_:)` call resumes scanning from where the previous call left off rather than rescanning the buffer's unconsumed tail from the start.
**Rationale**: (Swift implementation) `MessageFraming.swift`'s own doc comment states the alternative was measured at 114 seconds to decode a single 256 KB line — an O(n²) cost from rescanning already-examined bytes on every call. The cursor is what makes decoding linear in the number of bytes fed rather than quadratic, and is why `decoder-feed-chunk-sized-input` is phrased as a SHOULD for callers rather than a correctness requirement: feeding the decoder one byte at a time still produces correct frames, it is only slow.
**Approved**: pending

**Decision**: `terminate()` distinguishes a child's own end-of-file from a teardown-induced one (`DescriptorReader.reachedEndOfStreamNaturally`) by recording "a teardown has begun" (`markTornDown()`) *before* sending SIGTERM, and only flushes `MessageFramingDecoder.finish()` on the pump's exit when that flag was never set for a live, un-EOF'd descriptor.
**Rationale**: (Swift implementation) SIGTERM kills an ordinary child, the kernel closes its write end, and a genuine end-of-file arrives well before `terminate()`'s own `stopAll()` closes anything — so end-of-file alone cannot tell the pump whether the child finished speaking on its own or was shot mid-sentence. Reading every end-of-file as "natural" would flush the decoder on exactly the forced-shutdown path this distinction exists to protect, fabricating a whole message out of half of one for `.newlineDelimited`, or turning an orderly kill into a thrown `truncatedMessage` for `.contentLength`.
**Approved**: pending

**Decision**: `SubprocessChannel.run(_:budget:)` always decodes as `.unframed`, discarding whatever `MessageFraming` value the caller's `configuration` specifies.
**Rationale**: `SubprocessChannel+Run.swift`'s own doc comment states this directly: a one-shot run has no messages to frame, it hands back one `Data` holding all of stdout, and honoring a caller's framing here would subject a plain capture to a streaming protocol's malformed-peer guard — the 16 MiB cap that fires when no delimiter has arrived in that many bytes — which would incorrectly reject delimiter-free output (the doc comment's own example is git's NUL-terminated, newline-free machine-readable status on a large repository) that was never malformed to begin with.
**Approved**: pending

**Decision**: `withWallClockBudget(_:_:)` cancels the losing task on either outcome (timeout or caller cancellation) but never awaits it before resuming its own continuation.
**Rationale**: `WallClockBudget.swift`'s own doc comment states that awaiting the loser would make the function's guarantee only as good as the wrapped operation's cooperation with cancellation — which blocking I/O and a synchronous `Process` wait cannot promise. The trade this decision accepts is that a caller observing `WallClockBudgetExceeded` (or, in `SubprocessChannel.terminate()`, the grace-period expiry built on this same primitive) has only *requested* the loser's teardown, not confirmed it has finished, at the moment its own `async` call returns.
**Approved**: pending

**Decision**: A failing descriptor close is silent: the error code the underlying close reports is discarded, and no test exercises a failing close.
**Rationale**: It stands today because a close failure on an already-finished pipe offers the caller nothing to act on; closing the gap would mean choosing a signal (a log line or a thrown error) and adding a test that forces a bad-descriptor close. See `descriptor-close-failure-silent`.
**Approved**: pending

