
The reconciler is a stateless matching algorithm that turns "what a directory
scan just found" plus "what the registry already knew" into the records a
caller should write. Its one operation, the plan operation, matches each
scanned repository entry against the repository records already known, in a
fixed order: exact path matches first, then unresolved records are checked
against disk to tell "not reported" apart from "genuinely gone," then a move
pass matches a relocated repository by remote and, failing that, by
directory name, then whatever is still unclaimed becomes a new insert, and
whatever is still unaccounted for becomes a delete. The algorithm is pure and
side-effect-free so that "the interesting half of scanning" can be tested
without a database, a filesystem, or any particular execution context.
Nothing here performs I/O beyond the injectable repository-existence check;
reading the scan results off disk is the directory scanner's job (see the
`git-client-projects-git-repo-scanner` recipe), and writing the resulting
plan to a database is a separate caller's job.

