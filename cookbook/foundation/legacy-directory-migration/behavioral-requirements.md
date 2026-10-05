
- **move-when-only-legacy**: When the legacy directory exists and the new one does not, the migration MUST move the legacy directory to the new path and report that it migrated.
- **create-missing-parent**: The migration MUST create the new path's missing parent directories before the move.
- **nothing-to-migrate**: When neither directory exists, the migration MUST change nothing and report that there was nothing to migrate.
- **already-migrated**: When only the new directory exists, the migration MUST change nothing and report that it was already migrated.
- **same-directory**: When the two paths resolve to the same directory, after standardizing them and resolving symbolic links, the migration MUST change nothing and report that it was already migrated.
- **both-exist-touches-neither**: When both directories exist and the new one is not a placeholder, the migration MUST change neither and report that both exist.
- **placeholder-by-markers**: When markers are given and the new directory holds none of them as a direct child, the migration MUST treat it as a placeholder. A marker in a subdirectory MUST NOT count. With no markers given, the new directory is never a placeholder.
- **empty-placeholder-removed**: The migration MUST remove an empty placeholder with an operation that fails if anything appeared in it, then move the legacy directory into its place and report that it migrated.
- **non-empty-placeholder-aside**: The migration MUST rename a non-empty placeholder to a free sibling named `<name>.preempted-<timestamp>`, adding `-1`, `-2`, … up to 100 attempts when that name is taken. It MUST then move the legacy directory into place and report the aside location. It MUST NOT delete the placeholder's contents.
- **rename-only**: Every move MUST be an atomic rename that fails rather than replacing an existing destination or crossing a volume. The migration MUST NOT fall back to a copy.
- **restore-placeholder-on-failure**: When the move fails after a placeholder was renamed aside, the migration MUST rename the placeholder back to the new path and rethrow the original error. If putting it back also fails, the migration MUST throw an error that carries both the original error and the aside location.
- **run-before-use**: Callers MUST run the migration before anything opens files in the new directory, because the placeholder check lists the directory and then moves it.

