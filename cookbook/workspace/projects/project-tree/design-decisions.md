
**Decision**: `ProjectTreeNode.init` and `add(_:)` are `fileprivate`, and
`children` is `private(set)`, so only `ProjectTree.build` (same file) can
shape the tree.
**Rationale**: The type's own doc comment frames the tree as a display
projection of the registry — "the folders that lead to projects, and the
projects themselves" — not a general-purpose mutable collection a caller
should be free to reshape after the fact; restricting construction to the
file that computes the tree's invariants (sorted order, one node per path)
keeps a caller like `ProjectBrowserViewController` from building a tree that
disagrees with those invariants.
**Approved**: pending

**Decision**: a project's displayed `name` comes from `repo.name`
(`build-leaf-name-from-registry`), never from the trail-computed path
component that a purely path-derived name would have produced.
**Rationale**: `GitRepo.name`'s own doc comment says it is "seeded from the
directory name, then the user's to change" (`GitRepo.swift`) — the
registry, not the filesystem, is the source of truth for what a project is
called once a user has renamed it, and `ProjectTreeTests.testAProjectRowTakesItsNameFromTheRegistry`
exists specifically to pin this choice down.
**Approved**: pending

**Decision**: `build`'s ancestor-reuse step (`build-ancestor-reuse-by-path`)
matches an existing `byPath` entry purely by `path`, without checking whether
that entry `isFolder`.
**Rationale**: The source gives no rationale for this beyond the general
one-node-per-path intent stated for the leaf case ("this must not
duplicate"); because the check is not repeated for the ancestor
case, a path that is simultaneously an ancestor for one repo and the leaf
for another can end up represented inconsistently — see
`project-tree-leaf-path-collision`, the pending decision this recipe records
rather than resolves.
**Approved**: pending

**Decision**: A repository whose path equals another repository's ancestor folder path produces two sibling nodes at that path, one folder and one project, because the duplicate-leaf guard only matches an existing project node (`project-tree-leaf-path-collision`).
**Rationale**: The source's reuse guard checks `existing.repo != nil`, so a folder registered earlier at the same path falls through and a second node is added; which repository is processed first decides which node is created first, and PT-010 records the current outcome. Closing it needs a rule for whether the folder is replaced, merged, or kept beside the project.
**Approved**: pending

**Decision**: A repository whose path standardizes to no components (such as `/`) is silently dropped from the tree with no error, log, or signal (`project-tree-degenerate-path-dropped`).
**Rationale**: The source's trail computation returns an empty list for such a path and the build loop skips the repository with `continue`; no test constructs a degenerate path. Closing it needs a product decision on how the project chooser should represent such a repository (an error row or a log line) plus a test asserting it.
**Approved**: pending

