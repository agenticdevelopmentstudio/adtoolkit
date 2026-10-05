
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| legacy-directory-migration-001 | move-when-only-legacy | Legacy holds `stenographer.db`; the new directory is absent. | Reports migrated; the legacy path is gone; the new directory holds the file (test: movesLegacyWhenOnlyLegacyExists). |
| legacy-directory-migration-002 | nothing-to-migrate | Neither directory exists. | Reports nothing to migrate (test: nothingWhenNeitherExists). |
| legacy-directory-migration-003 | already-migrated | Only the new directory exists. | Reports already migrated; nothing changes (test: alreadyMigratedWhenOnlyCurrentExists). |
| legacy-directory-migration-004 | both-exist-touches-neither | Both hold `stenographer.db`, with no markers given. | Reports both exist; both files are unchanged (test: bothExistTouchesNeither). |
| legacy-directory-migration-005 | create-missing-parent | The new path's parent does not exist. | Reports migrated; the new directory exists (test: createsMissingParentOfCurrent). |
| legacy-directory-migration-006 | empty-placeholder-removed | The new directory is empty; marker `stenographer.db`. | Reports migrated; the new directory holds the legacy file (test: emptyPlaceholderIsReplaced). |
| legacy-directory-migration-007 | non-empty-placeholder-aside | The new directory holds only `cache.tmp`; marker `stenographer.db`. | Reports migrated with an aside location; the aside holds `cache.tmp`; exactly one aside exists (test: nonEmptyPlaceholderIsMovedAside). |
| legacy-directory-migration-008 | placeholder-by-markers | The new directory holds the marker. | Reports both exist; both are unchanged (test: currentHoldingMarkerIsBothExist). |
| legacy-directory-migration-009 | placeholder-by-markers | Both exist, the marker list is empty, and the new directory holds only `cache.tmp`. | Reports both exist; nothing moves (test: emptyMarkersBothExistIsBothExist). |
| legacy-directory-migration-010 | placeholder-by-markers | The new directory holds the marker only inside a subdirectory. | It is a placeholder: moved aside with its nested file intact; the legacy directory takes its place (test: markerInSubdirectoryDoesNotCount). |
| legacy-directory-migration-011 | same-directory | Both paths are the same directory. | Reports already migrated; data unchanged (test: sameDirectoryIsAlreadyMigrated). |
| legacy-directory-migration-012 | same-directory | The new path is a symbolic link to the legacy directory. | Reports already migrated; the link and data are unchanged (test: currentSymlinkedToLegacyIsAlreadyMigrated). |
| legacy-directory-migration-013 | non-empty-placeholder-aside | Every timestamped aside name for now and the next two seconds is taken. | The placeholder goes to a name ending `-1` and keeps its contents (test: asideNameCollisionGetsSuffix). |
| legacy-directory-migration-014 | restore-placeholder-on-failure | The legacy directory's parent is read-only, so the move fails; the new directory is a non-empty placeholder. | Throws a permission error; the placeholder is back at the new path with its contents; no aside remains; legacy is unchanged (test: failedLegacyMoveRestoresPlaceholder). |

