
**Decision**: Give every operation its own fresh `FileManager()` inside its
queued closure, rather than sharing one `FileManager` instance across calls
or capturing `FileManager.default`.
**Rationale**: (Swift/Foundation implementation) `FileManager` is not
`Sendable`; capturing a shared instance across the actor boundary and the
`DispatchQueue` closure would either not compile under strict concurrency or
require an unsafe escape, while a fresh, cheap instance per call keeps every
closure trivially `Sendable`-correct (`fresh-file-manager-per-call`).
**Approved**: pending

**Decision**: Attempt the rename operation's move first and act on the
overwrite flag only after that move fails as an already-exists outcome,
rather than checking whether the destination path is occupied before ever
attempting the move.
**Rationale**: A pre-check would make a case-only rename on a
case-insensitive volume, and a rename where the source and destination path
are identical, both report "already exists" for the very file being
renamed — the exact failure that would make renaming a file to fix its own
casing impossible. Attempting the move first lets those two cases succeed
outright, since the underlying move succeeds on them without ever
consulting the overwrite flag (`rename-destination-not-precchecked`,
`rename-case-only-and-self-renames-succeed`).
**Approved**: pending

**Decision**: Implement the rename operation's overwrite path as move,
remove, move again, guarded to reproduce the underlying move operation's
own `EISDIR`/`ENOTDIR`/`ENOTEMPTY` refusals, rather than as a single atomic
replace.
**Rationale**: (Swift/Foundation implementation) Foundation has no API that
atomically replaces an occupied destination across both files and
directories. The doc comment records that an earlier hand-rolled version of
this sequence, without those guards, was strictly more destructive than the
`rename(2)` syscall it was meant to emulate — it would remove an occupying
directory that `rename(2)` itself would have refused to touch. The guarded
version accepts a narrower, explicitly documented failure window
(`rename-overwrite-failure-window`) instead of that broader, silent one.
**Approved**: pending

**Decision**: Route the delete operation's permanent-removal step, and the
removal inside the rename operation's overwrite sequence, through a direct
removal rather than through the Trash, even when the wider operation is one
a user might expect to be recoverable.
**Rationale**: The Trash option is the delete operation's own explicit,
caller-chosen flag; threading Trash semantics into a rename's internal
remove-then-replace step as well would silently change what "overwrite"
means for that call, and the Trash's renamed-on-collision behavior is not
something the `rename-overwrite-sequence` retry logic could correctly
account for.
**Approved**: pending

**Decision**: Report a read-directory child whose own type cannot be
determined with an unknown-type flag, rather than letting that one child's
failure abort or throw for the whole listing.
**Rationale**: A directory can contain an entry this process cannot stat —
a permission-denied child, or one that disappears between being listed and
being inspected — and treating that as fatal for every other, readable
child in the same directory would make an otherwise-successful listing
unusable because of one uninspectable entry
(`read-directory-unreadable-child-is-unknown`).
**Approved**: pending

