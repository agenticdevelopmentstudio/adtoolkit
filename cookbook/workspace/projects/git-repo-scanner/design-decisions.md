
**Decision**: A `.git` directory that contains no `HEAD` file is not treated
as a repository, and the walk continues underneath it rather than stopping.
**Rationale**: The doc comment states the check is for a `.git` "one git
would actually open," since a hook-only `.git` folder "invents a project and
hides the real repositories underneath it" (`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: A `.git` entry that is a file rather than a directory causes
the whole containing directory to be skipped entirely, rather than being
treated as an empty repository or descended into.
**Rationale**: The doc comment explains that such a `.git` "is an absorbed
submodule or a linked worktree, neither of which is a project in its own
right" (`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: `rootSkipPatterns` is applied only at depth 1, never at any
other depth.
**Rationale**: The doc comment gives the reason directly: a folder named
`Music` eight levels down "is just a folder someone named that — quite
possibly a project's asset directory," unlike `~/Music`, which is a media
library (`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: A repository's origin remote is read by parsing
`.git/config` directly rather than by shelling out to `git config
--get remote.origin.url`.
**Rationale**: The type-level doc comment states the reasoning as a measured
cost: "200-odd `git config` subprocesses cost more than the whole walk"
(`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: `scan()` always returns its results sorted by path, including
when it stops early due to cancellation, rather than returning them in
discovery order.
**Rationale**: The doc comment ties the sort directly to test reliability:
results are "sorted by path so two scans of an unchanged tree produce
identical output" (`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: `defaultRootSkipPatterns` lists `"Dropbox"` and `"* Dropbox"`
as two separate entries rather than a single glob covering both.
**Rationale**: The doc comment explains the naming split directly: "Dropbox
appears twice because it names its folder two ways: `Dropbox` for a personal
account, `<Company> Dropbox` for a team one. A glob is the only way to cover
the second, and the first is not a glob" (`GitRepoScanner.swift`).
**Approved**: pending

**Decision**: An unreadable directory (a thrown `contentsOfDirectory` call)
is caught and skipped via `continue`, letting the walk proceed to the
remaining directories rather than aborting the whole scan.
**Rationale**: The inline comment states the reasoning directly: "An
unreadable directory is not a reason to abandon the walk — `~` has plenty of
them" (`GitRepoScanner.swift`). This decision explains why the
walk continues; it does not settle whether the resulting silence about
*which* directories were skipped is also intended — that is the pending
decision below on `unreadable-directory-error-visibility`.
**Approved**: pending

**Decision**: An unreadable directory, including a wholly missing scan root, is skipped with no log, no progress field, and no returned entry, so it is indistinguishable from a directory that was simply empty (`unreadable-directory-error-visibility`).
**Rationale**: The source's catch around the directory read does only `continue`; skipping is intended for the walk, but whether the silence about which directories were skipped is also intended is undecided. Closing it means counting skipped directories in the progress value, logging them, or documenting silence as the contract.
**Approved**: pending

