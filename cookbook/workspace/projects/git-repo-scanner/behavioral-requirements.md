
- **default-scan-root**: Construction MUST default `roots` to the current
  user's home directory when the caller passes no value.
- **default-skip-patterns**: Construction MUST default `rootSkipPatterns`
  to the built-in default skip patterns (`["Library", "Music", "Pictures",
  "Movies", "Dropbox", "* Dropbox", "Google Drive"]`) when the caller
  supplies no value.
- **hidden-directories-excluded**: The descend decision MUST return false
  for any child whose name begins with `.`, at every depth.
- **pruned-directories-excluded**: The descend decision MUST return false
  for any child whose name is exactly `node_modules`, `venv`,
  `__pycache__`, `build`, `dist`, `target`, `Pods`, or `Carthage`, at every
  depth.
- **root-level-skip-patterns**: The descend decision MUST return false for
  a child at depth exactly 1 whose name matches any pattern in
  `rootSkipPatterns`, and MUST NOT apply `rootSkipPatterns` at depth 0 or at
  any depth greater than 1.
- **case-insensitive-pattern-matching**: Comparing a folder name against a
  pattern MUST be case-insensitive.
- **symbolic-links-excluded**: The descend decision MUST return false for
  any child that is a symbolic link, at every depth, regardless of whether
  it also matches a skip pattern or is a directory.
- **git-directory-repository-detection**: A child directory MUST be treated
  as a repository only when it directly contains an entry named `.git`
  that is itself a directory and that directory contains a file named
  `HEAD`; detection MUST check for that `HEAD` file's existence inside the
  candidate `.git` directory.
- **hook-only-git-folder-not-a-repository**: A `.git` directory that exists
  but contains no `HEAD` file MUST NOT be treated as a repository, and the
  walk MUST continue into that directory's own children.
- **git-file-skipped-entirely**: When a child directory contains a `.git`
  entry that is not itself a directory (a submodule gitlink or a linked
  worktree's `.git` file), the walk MUST skip that directory and MUST NOT
  descend into its subtree.
- **repository-not-descended-into**: Once a directory is recognized as a
  repository under `git-directory-repository-detection`, the walk MUST NOT
  descend into that directory's children.
- **single-scanned-git-repo-per-repository**: For each directory recognized
  as a repository, the walk MUST append exactly one scanned-repository
  result whose `path` is that directory's path and whose `remote` is the
  origin remote read from that directory's `.git` directory.
- **origin-remote-extraction**: Reading the origin remote MUST parse the
  `.git/config` file as line-oriented INI text, MUST locate the section
  whose trimmed, space-stripped line equals the literal string
  `[remote"origin"]`, and within that section MUST return the trimmed
  value after the first `=` on the first line whose trimmed key equals
  `url`.
- **origin-remote-absent-cases**: Reading the origin remote MUST return no
  value when the `config` file cannot be read as UTF-8 text, when no
  `[remote "origin"]` section is present, or when that section's `url`
  value is empty after trimming whitespace.
- **sorted-idempotent-results**: A scan MUST return its accumulated results
  sorted ascending by `path` string comparison, both when it completes
  normally and when it stops early due to cancellation.
- **progress-reported-per-visited-directory**: For every directory popped
  from the walk's stack, a scan MUST report progress exactly once, before
  reading that directory's children, carrying the running count of
  directories visited, the count of repositories found so far, and the
  directory's current path.
- **cancellation-checked-per-directory**: Before processing each directory
  popped from the walk's stack, a scan MUST check for cancellation; when
  cancellation is signaled, the scan MUST stop immediately and return the
  results accumulated so far, sorted per `sorted-idempotent-results`.
- **default-callbacks-are-no-ops**: Scanning MUST default the cancellation
  check to one that always reports "not cancelled" and MUST default
  progress reporting to none when the caller supplies neither.
- **depth-first-stack-traversal**: A scan MUST traverse using a
  last-in-first-out stack of (location, depth) pairs seeded with each root
  at depth `0`, popping the most recently pushed entry and pushing each
  descended child at `depth + 1`.
- **multiple-roots-scanned-independently**: When `roots` contains more than
  one location, a scan MUST walk each root in the order given, accumulating
  every root's results into one combined array before the final sort.
- **concurrent-scans-are-independent**: The scanner MUST be safely usable
  across concurrent contexts, and a scan MUST hold all of its mutable
  traversal state (the results found so far, the visited set, the
  traversal stack) local to that one call rather than in any shared state
  of the scanner itself; the reported progress value MUST likewise be
  safely usable across concurrent contexts.
- **unreadable-directory-error-visibility**: when reading a directory's contents fails (permission denied, or a scan root that does not exist), the scan MUST skip that directory and continue the walk; the failure is not surfaced in any observable form: no log call, no field on the reported progress, and no entry in the returned array (see Design Decisions).

