
- **save-assigns-id-stamps**: A save with an empty id MUST insert with a fresh id; a save with an id MUST update. The stored record MUST be returned with its assigned id and stamps, keeping the original creation time of an existing record.
- **name-required**: A client or project name MUST be trimmed and MUST NOT be empty (`missingName`).
- **name-unique**: A client or project name MUST NOT collide (by the shared unique-name comparison) with any other record of the same kind, archived included (`duplicateName`).
- **project-rounding-range**: A project's rounding minutes MUST be inside 1 to 240; otherwise the save MUST be refused (`invalidRounding`), not clamped.
- **rate-range**: A project's or repo's rate, when present, MUST be inside 0 to 10,000,000 cents; otherwise the save MUST be refused (`invalidRate`).
- **project-client-dangling**: A project whose client id no longer resolves MUST be stored with no client rather than a dangling id.
- **repo-root-required**: A repo's root MUST be trimmed and non-empty (`missingRepoRoot`), and its project MUST exist (`unknownProject`).
- **repo-unique-claim**: A (root, branch) pair, both trimmed, MUST NOT be claimed by another repo row (`repoAlreadyClaimed`).
- **client-delete-guard**: Deleting a client MUST be refused when it has billed or paid entries (`clientHasBilledEntries`); the count and the delete MUST share one transaction.
- **project-delete-guard**: Deleting a project MUST be refused when it has any entry (`projectHasEntries`); the count and the delete MUST share one transaction.
- **resolve-claim**: `resolveRate` MUST return the repo and project that claim a root and branch over the live tables, archived projects included.
- **tracked-flag**: Work MUST be tracked only when both the claiming repo row and its project have billing enabled; Unassigned work has no switch and is tracked.
- **derive-session**: `deriveSegments` MUST resolve the claim, read the session's activity through the cache, derive runs, replace the session's derived segments with the claim, tracked flag, current zone and history start, stamp the watermark with the value read at selection time, and return how many segments were written.
- **unassigned-still-written**: Unassigned work MUST still be written when unassigned tracking is on.
- **unassigned-opt-out**: With unassigned tracking off and no claiming project, `deriveSegments` MUST write nothing new, MUST close the session's open derived runs, MUST stamp the watermark, and MUST return 0.
- **close-open-runs**: Closing an open run MUST end it where the matching run ends when the session is treated as finished, or at its own start with zero seconds when no run covers it.
- **refusals-are-sentences**: Every refusal MUST present a sentence fit to show the user.

