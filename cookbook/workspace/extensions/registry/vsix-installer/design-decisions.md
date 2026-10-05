
**Decision**: Move an existing `destination` directory aside before moving the
new payload in, rather than deleting the old copy first.
**Rationale**: A failure during the second move can then restore the first;
deleting the old copy first would leave the user with neither version if the
second move then failed — the one outcome that would make an update button
unsafe to press (doc comment; `moveIntoPlace`).
**Approved**: pending

**Decision**: Check destination containment twice — once as a predicate over
the identifier and version strings (`ExtensionIdentityComponent.isSafe`), once
as a fact about the actual resolved destination path
(`ExtensionResourcePath.canonicalChild`/`url(isContainedIn:)`).
**Rationale**: The two checks fail for different reasons. A future change to
`directoryName(identifier:version:)` that joined its parts differently would
slip straight past the string-level predicate and still be caught by the
path-level check, which is closer to what `moveIntoPlace`'s underlying
`rename(2)` actually resolves.
**Approved**: pending

**Decision**: Canonicalize the install directory's *parent*, which exists,
and append the new component to that — rather than canonicalizing the full,
not-yet-existing destination path.
**Rationale**: `resolvingSymlinksInPath()` drops a leading `/private` only
when what remains still names something real. The version of this guard that
canonicalized the whole destination refused every ordinary install into an
extensions folder reached through `/private` (a macOS temporary directory, or
a home on another volume) with `unsafeIdentity`, naming a perfectly ordinary
`<publisher>.<name>-<version>` (`ExtensionResourcePath.swift`; test `aPrivateRootedInstallDirectoryStillInstalls`).
**Approved**: pending

**Decision**: Match superseded directories by decoding each candidate's own
`package.json` and comparing its `identifier`, never by matching the
candidate's folder name against a naming convention.
**Rationale**: A hand-installed extension or a dev checkout is named however
its author named it, and those are exactly the copies whose survival would
shadow the extension just installed if the sweep trusted names instead of
content (doc comment; test `supersedesAHandNamedDirectory`).
**Approved**: pending

**Decision**: Report the failure of a rollback (moving the aside back after
the new payload's move also failed) as a distinct outcome from the original
move failure, rather than the same `try?`-discarded error both used to share.
**Rationale**: The thrown error used to carry only the original failure's
reason, so the one outcome this whole aside-and-swap dance exists to
prevent — the user left with no version of the extension at all — was
reported in exactly the same words as the safe outcome where the previous
version simply went back. The aside's own name is included because a person
can move it back by hand and nothing else on disk says where it went.
**Approved**: pending

**Decision**: Let a superseded copy that cannot be removed, and a
crash-recovery aside that cannot be restored or discarded, fail quietly (a
logged warning or error) rather than fail the calling operation.
**Rationale**: In both cases the alternative on-disk state is already
correct, or already the best available outcome, by the time the failure
happens — the new version is installed and loadable, or the aside is still
the only surviving copy and deleting it would turn a recoverable state into
an unrecoverable one. Throwing would report an install that succeeded (or a
recovery that did the safe thing) as having failed.
**Approved**: pending

**Decision**: Concurrent installs into one install directory are not serialized or detected as overlapping.
**Rationale**: `VSIXInstaller` is a stateless `Sendable` struct with no lock, so two overlapping calls each run `recoverInterruptedInstalls`, the supersede scan, `moveIntoPlace`, and cleanup against the same tree. Closing it would take a per-install-directory lock (or a single serialized caller); the only construction sites are in `ExtensionsCoordinator.swift`, and nothing in the installer itself prevents two overlapping installs.
**Approved**: pending

