
The git repository scanner walks one or more directory trees looking for
git working trees ("projects"). It skips hidden dot-directories and known
build or dependency folders at every depth, skips symbolic links at every
depth, and skips caller-supplied glob patterns only directly under a scan
root. A directory holding a working `.git` directory (one with a `HEAD`
file) is reported as a scanned repository and is not descended into; a
`.git` that is a file rather than a directory (an absorbed submodule or a
linked worktree) is skipped entirely; a `.git` directory with no `HEAD` (a
hook-only folder) is ignored and the walk continues underneath it. Each
found repository's origin remote is read directly out of `.git/config`,
never by invoking the `git` executable. Scanning runs synchronously off the
main execution context, checks cancellation and reports progress once per
visited directory, and returns results sorted by path so repeated scans of
an unchanged tree are byte-identical.

