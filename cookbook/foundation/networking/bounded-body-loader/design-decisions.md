
**Decision**: The transfer is driven by a delegate-style callback on a
dedicated data task rather than by an async byte-stream API.
**Rationale**: (Swift/Foundation implementation) `URLSession.bytes(from:)`'s
`AsyncBytes` yields one `UInt8` per `await`, measured at 23.8 MB/s against
an in-process stub where `data(from:)` — which cannot be bounded — measures
2.5 GB/s. A delegate on a data task gets whole chunks at the system's rate
while still checking the ceiling per chunk, so the 20-second worst case on
a 512 MB artifact stays a delegate callback loop rather than a
half-million-iteration `await` loop, and the same code path also serves
the metadata read behind every keystroke of a search field.
**Approved**: pending

**Decision**: The session's callback object is a separate object that
holds only the shared state, rather than the loader being its own
delegate.
**Rationale**: (Swift implementation) `URLSession` retains its delegate for
as long as the session is not invalidated. A loader that were its own
delegate would be retained by its own session and could never be
deallocated, so it could never reach its own teardown to invalidate that
same session — a retain cycle with no way out. Splitting the delegate into
an object with no reference back to the loader breaks that cycle.
**Approved**: pending

**Decision**: The byte ceiling is checked twice — once against the
declared expected length before any chunk is read, and again against the
running total as chunks arrive — rather than relying on either check
alone.
**Rationale**: The header alone is the sender's unverified claim: an
understated declared length costs the sender nothing to write and would
let an oversized body slip past a header-only check, which is exactly what
the understated-length test vector (networking-005) pins. The running
check alone would still work correctly but would always cost reading at
least one chunk before refusing an obviously oversized answer; checking
the header first lets the claimed-oversized case (networking-004) refuse
before a single byte of a claimed-oversized transfer is read.
**Approved**: pending

**Decision**: An overflowed transfer's buffer is reset to empty
immediately, rather than left populated until completion is signaled.
**Rationale**: Holding a body that has already been refused is exactly the
unbounded-memory condition the ceiling exists to prevent, and cancellation
is not instantaneous — more chunks can still arrive on the wire before it
takes effect. Clearing the buffer the moment the overflow is detected
keeps that window from costing any additional retained memory.
**Approved**: pending

**Decision**: All per-transfer state across every concurrent call on one
loader instance is guarded by a single lock, rather than one lock per
transfer or an actor.
**Rationale**: (Swift implementation) The writes arrive from the session's
delegate queue, which is not an async context, ruling out an `actor`
without a bridging layer. A single lock over a dictionary keyed by the
transfer's identifier is the simplest construction that still keeps every
transfer's bookkeeping correct — each critical section is a short
dictionary read-modify-write, not a long hold.
**Approved**: pending

**Decision**: Reading the body does not validate the HTTP status code, and
the too-large failure carries the response it had (or nothing) rather
than resolving the status-versus-size question itself.
**Rationale**: A response whose body is both oversized and behind an error
status (a proxy's lengthy 503 page, for instance) is more usefully reported
by its status than by its size — reporting "too large" would send a reader
looking for a limit to raise when the real fix is to retry later. Deciding
that precedence needs the status code, and this loader's only job is
bounding bytes, so it hands the response back either way and lets the
caller — which already knows what "success" means for its own request —
make that call, exactly as the extension-registry client's own body helper
does immediately after unwrapping the too-large failure.
**Approved**: pending

**Decision**: The accumulated buffer's preallocated capacity is capped at
1,048,576 bytes (1 MiB) regardless of how large the declared expected
length claims the body will be.
**Rationale**: The limit itself can be as large as 512 MB for the artifact
path this loader serves elsewhere in the module; reserving capacity for
the full claimed length up front would commit a very large allocation
before a single byte has been verified as real. Capping the hint at 1 MiB
still avoids repeated reallocation for the common case (a small metadata
response) while never letting the preallocation itself become the
oversized-allocation problem the ceiling exists to prevent.
**Approved**: pending

