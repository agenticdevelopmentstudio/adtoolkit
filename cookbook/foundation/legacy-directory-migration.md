---
id: 1996A181-6B83-4000-9671-7E872C625B4C
title: "Legacy Directory Migration"
domain: adtoolkit://cookbook/foundation/legacy-directory-migration
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A one-time, lossless move of a data directory to its new name, done only by an atomic same-volume rename that never copies, merges, replaces or deletes data."
platforms:
  - swift
  - macos
tags:
  - foundation
  - file-system
  - migration
depends-on: []
related:
  - adtoolkit://cookbook/foundation/defaults-domain-migration
  - adtoolkit://cookbook/foundation/file-system
references: []
approved-by: ""
approved-date: ""
---

# Legacy Directory Migration

## Overview

Moves an app's data directory from a legacy location to its new one exactly once, at launch, after a rename of the app or its support folder. The only operations it uses are an atomic rename on the same volume that refuses to replace an existing destination, and removal of an empty directory. It never copies, merges or deletes data. When both directories hold data, it touches neither and tells the caller, because merging two live stores is not something a launch-time migration may guess at.

A fresh launch can create the new directory before the migration runs. The caller can name **markers**, files whose presence at the top level of the new directory proves it holds real data. A new directory with none of them is a placeholder: an empty one is removed, and a non-empty one is renamed aside so the legacy directory can take its place.

## Behavioral Requirements

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

## Appearance

Not applicable: The migration is not a visual component.

## States

Not applicable: The migration is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The migration presents no UI.

## Conformance Test Vectors

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

## Edge Cases

- **Null / empty input**: An empty marker list disables placeholder detection, so two existing directories always report both exist.
- **Boundary values**: Only a marker at the new directory's top level counts; a nested copy does not. After 100 taken aside names the migration throws, and nothing has moved.
- **Concurrent access**: The placeholder check and the move are separate steps. A writer that creates a marker in between would be moved aside with the placeholder, so the caller runs the migration before anything opens the directory. Removal of an empty placeholder fails instead of deleting anything that appeared.
- **Error states**: A cross-volume move, an existing destination, or a file system without exclusive-rename support throws, and nothing is moved. A failure after the aside rename restores the placeholder, or throws an error carrying its aside location.
- **Offline / disconnected state**: Not applicable: The migration has no network access.
- **Cancellation**: Not applicable: The migration is a single synchronous call with no cancellation point.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| legacy | directory path | none, required | The directory to move from. |
| current | directory path | none, required | The directory to move to. |
| markers | list of file names | empty | Files whose presence at the top of `current` proves it holds real data. |
| fileManager | file-system handle | the default | The file system used for existence checks, listing and creating the parent; injectable for tests. |

The migration reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The migration defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The migration contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The migration presents no UI.

## Feature Flags

Not applicable: The migration contains no feature-flag reference.

## Analytics

Not applicable: The migration contains no analytics call.

## Privacy

- **Data handled**: Directory paths and the names of the files directly inside the new directory; it never reads file contents.
- **Storage**: None of its own; it only renames the caller's directories.
- **Transmission**: None; it performs no network access.
- **Retention**: A non-empty placeholder is kept at its aside location; the migration never deletes it.

## Logging

Not applicable: The migration calls no logging API; the caller reports the outcome, including a leftover when both exist.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific. It is a caseless `enum` with one static `migrate(from:to:markers:fileManager:)` returning an `Outcome` (`nothingToMigrate`, `migrated`, `alreadyMigrated`, `bothExist`, `migratedReplacingPlaceholder(asideAt:)`) and throwing `MigrationError.rollbackFailed(original:asideAt:)` or a `POSIXError`. Moves use `renamex_np` with `RENAME_EXCL`, which fails with `EEXIST` on an existing destination and `EXDEV` across volumes; a file system without it fails with `ENOTSUP`. An empty placeholder is removed with `rmdir`.
- **Compose**: On Android, `File.renameTo` within app-private storage is the atomic rename; check that the destination is absent first, because `renameTo` gives no exclusive-create guarantee on every file system.
- **React/Web**: Not applicable: a browser has no directory-rename primitive; storage moves are key copies, which this contract forbids.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic.
- **WinUI 3**: `MoveFileEx` without `MOVEFILE_REPLACE_EXISTING` and without `MOVEFILE_COPY_ALLOWED` gives the same exclusive, same-volume rename.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/LegacyDirectoryMigration.swift` |

## Design Decisions

**Decision**: When both directories hold data the migration moves nothing and reports both exist.
**Rationale**: Merging two live databases at launch would have to guess which side wins; leaving both lets the caller use the current one and report the leftover.
**Approved**: pending

**Decision**: A non-empty placeholder is renamed aside, never deleted.
**Rationale**: The migration's guarantee is that no data is ever lost; a placeholder's contents are probably disposable, but only the user can decide that.
**Approved**: pending

**Decision**: Only an exclusive same-volume rename is used, with no copy fallback.
**Rationale**: A rename is atomic and cannot leave a half-copied directory; failing on a cross-volume move is safer than a copy that a crash could interrupt.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |

`separation-of-concerns` passes because the type only moves a directory; when to call it and what the data means stay with the host. `unit-test-coverage` passes because `AgenticToolkitCoreTests/LegacyDirectoryMigrationTests.swift` covers every outcome, placeholder handling, aside-name collisions and rollback. `idempotent-operations` passes because a second run after a move finds only the new directory and reports already migrated.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
