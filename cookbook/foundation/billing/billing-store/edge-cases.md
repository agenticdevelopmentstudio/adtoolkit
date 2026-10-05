
- Duplicate-name and repo-claim checks read and then write without a shared transaction, so two concurrent saves can both pass the check; the host's unique index is the backstop for repos, and nothing backstops names.
- A zero-length or malformed session start is handled by derivation.
- An error mid-derivation propagates before the watermark is stamped, so the session is re-derived next pass.
- Deleting a repo has no precondition.

