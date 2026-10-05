
- **project-tree-node-stored-shape**: a tree node MUST store exactly four
  properties — `name` (string), `repo` (an optional repository
  reference), `path` (string), and `children` (a list of tree nodes), the
  last exposed read-only and defaulting to an empty list — set through
  construction restricted to this component.
- **project-tree-node-is-folder-derivation**: `isFolder` MUST be a
  computed property that returns whether `repo` is absent; a node is a
  folder if and only if it was constructed with no repository.
- **project-tree-node-construction-restricted**: construction and
  child-appending MUST both be restricted to this component; no other
  component MUST be able to construct a tree node or append a child to an
  existing one directly — only the tree-building operation MUST be able
  to shape the tree.
- **repositories-in-display-order-leaf-passthrough**: `repositoriesInDisplayOrder`
  MUST return itself as a single-element list immediately, without
  inspecting `children`, when the node holds a repository.
- **repositories-in-display-order-folder-recursion**: when the node holds
  no repository, `repositoriesInDisplayOrder` MUST return the flattened
  concatenation of every child's own `repositoriesInDisplayOrder`, so the
  flattened result MUST contain only nodes that hold a repository, in the
  same depth-first order `children` is stored in at every level.
- **build-default-home-directory**: the tree-building operation's
  home-directory input MUST default to the current user's home directory,
  evaluated once per call when the caller supplies no explicit value.
- **build-path-standardization**: before computing anything else, building
  the tree MUST reduce both the home directory's path and every
  repository's path through the same path-standardization step, which
  strips exactly one trailing `"/"` when the string is longer than one
  character and leaves every other string unchanged — MUST NOT collapse
  repeated slashes, resolve `".."` or `"~"`, or normalize case.
- **trail-under-home-detection**: computing a path's trail MUST classify a
  path as under home only when its component count is strictly greater
  than home's component count AND its first components equal home's
  components exactly; a path identical to home itself MUST NOT be
  classified as under home.
- **trail-under-home-truncation**: for a path classified as under home,
  computing its trail MUST start the returned trail at the first
  component after home's own components, omitting every component of
  home itself from both the trail's names and its count.
- **trail-outside-home-leading-slash**: for a path NOT classified as under
  home, computing its trail MUST prepend `"/"` to the name of the trail's
  first component only; the name of every other component, at any depth,
  MUST have no leading slash.
- **trail-absolute-path-always-full**: every trail entry's path MUST be
  computed as the full absolute path from the filesystem root through
  that component, regardless of whether that component's displayed name
  was truncated for being under home; two folders with the same displayed
  name under different ancestors MUST therefore be tracked as distinct
  entries because their path values differ.
- **build-ancestor-reuse-by-path**: for each ancestor step in a
  repository's trail (every entry except the last), building the tree
  MUST reuse the existing tree node already registered at that step's
  path, if one exists, as the parent for the next step, and MUST NOT
  create a second node for the same path; this reuse check MUST NOT
  inspect the existing node's folder-or-project state before treating it
  as the parent.
- **build-ancestor-folder-creation**: when no node is yet registered at an
  ancestor step's path, building the tree MUST construct a new folder
  node, register it at that path, and append it to the running parent (or
  to the roots when there is no parent yet) before continuing to the next
  step.
- **build-leaf-name-from-registry**: the tree node building constructs for
  a repository's leaf MUST take its `name` from the repository's own
  name, never from the trail-computed component name that a path-only
  derivation would have produced.
- **build-duplicate-leaf-path-dropped**: when a node is already registered
  at the leaf's path and that node holds a repository, building the tree
  MUST skip constructing a second node for the current repository and
  MUST NOT add it to the tree, because "the registry allows [two rows for
  one path] and this must not duplicate".
- **build-roots-sort-order**: building the tree MUST sort the roots so
  every folder sorts before every project, and MUST NOT consider `name`
  when two roots differ in folder-or-project state.
- **build-roots-name-tiebreak**: within two roots of the same
  folder-or-project state, building the tree MUST order them by a
  locale-aware, case-insensitive comparison of `name`, ascending.
- **build-recursive-sort**: after sorting the roots, building the tree
  MUST recursively apply the same sort so every node's `children`, at
  every depth of the resulting forest, is sorted by the same
  folders-first, case-insensitive-alphabetical rule.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **build-empty-input-yields-empty-tree**: building the tree from an empty
  registry MUST return an empty array; nothing in the build loop runs
  when the registry is empty, so the roots MUST stay empty.
- **project-tree-leaf-path-collision**: when a repository's leaf path was already registered as a folder node (created earlier as another repository's ancestor step), building the tree constructs a second, project-flavored node at the same path, re-points the path registration at it, and appends it to the parent (or roots) without removing the earlier folder node; both sibling nodes (one folder, one project) at the identical path appear in the result (see Design Decisions).
- **project-tree-degenerate-path-dropped**: a repository whose standardized path splits into zero components (for example the root path `/`) yields an empty trail, and building the tree silently omits that repository: it appears in no root, no folder, and no count, with no error, log call, or other signal to the caller (see Design Decisions).

