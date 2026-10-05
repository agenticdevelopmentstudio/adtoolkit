
This is a stateless collection of pure functions that turns "what tabs are
already stored" plus "what checkouts a fresh worktree listing just
reported" into the changes a caller should make: which stored tabs to keep
as-is, which checkouts need a brand-new tab group, and which stored tabs
point at a directory that is truly gone rather than merely unreachable.
Its own documentation states it is pure — no disk access except through an
injected existence check — so it is testable and the project controller
stays the only thing that acts on the answer. Its sole caller reads the
stored tabs and the current checkouts, builds a plan, then picks a
starting layout for any new checkout and builds that checkout's tab
records, before persisting the combined result. This file performs no
persistence itself and reads no other stored state; every answer is a pure
function of its arguments.

