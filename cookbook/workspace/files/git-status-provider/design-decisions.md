
**Decision**: Overlapping `refresh()` calls coalesce into at most one
queued follow-up run, tracked with a single `isQueued` boolean rather than a
counter or a queue of distinct requests.
**Rationale**: Per the doc comment, "a burst of N requests costs two git
processes rather than N" — a run already in flight started before any
request that arrives during it, so it cannot be the answer to that request;
one trailing run answers every such caller, and nothing distinguishes one
pending caller's interest from another's.
**Approved**: pending

**Decision**: A cancellation of the underlying status check is reported as
the unavailable case, the same result used for every other failure, rather
than being propagated or given its own case.
**Rationale**: The doc comment states the reasoning directly: cancellation
is "not a status failure... but the one thing it is certainly not is
evidence that the tree is clean," so treating it as "we do not know" rather
than propagating the cancellation keeps every caller of the refresh
operation on one simple, non-throwing result type.
**Approved**: pending

**Decision**: On Apple platforms, the error-level log built in the refresh
operation's failure branch never uses the error's full localized
description, and for a git-client error uses a sanitized description
property instead of the error's full description property.
**Rationale**: The full-description property interpolates the
command-failure case's raw standard-error text, which is git's own output;
the source comment states the branch's logging rule plainly: "OSLog
records what was called, never what git said."
**Approved**: pending

**Decision**: On Apple platforms, `GitFileStatus` gets two color
properties, `color` (SwiftUI) and `nsColor` (AppKit), that must be kept in
semantic agreement, rather than one canonical color type both frameworks
convert from.
**Rationale**: SwiftUI's `Color` and AppKit's `NSColor` are not
interchangeable for the callers this extension serves; the doc comment
frames the duplication explicitly as "two spellings of one fact rather than
two facts" so that whichever framework draws the badge, red still means
deleted.
**Approved**: pending

**Decision**: The observation token's unregistration is driven by the
token's own release rather than an explicit `removeObserver` method; on
Apple platforms this is implemented by having the unregistration closure
hold the provider weakly and fire from the token's `deinit`.
**Rationale**: Per the doc comment, this is "modelled as a token rather
than an addObserver/removeObserver pair so a consumer cannot forget the
second half — the compiler's lifetime rules do the unregistering," and
holding the provider weakly keeps a live registration from being the thing
that keeps the provider itself alive.
**Approved**: pending

