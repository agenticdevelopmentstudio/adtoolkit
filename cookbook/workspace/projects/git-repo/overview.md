
This defines three related value types the project browser's scan pipeline
passes between its stages. The repository record is the registry's row for
a repository the app already knows about — identified by a unique id
rather than its path, "because a repository that moves keeps its settings,
its layout and its name" once some other component re-points the row. The
scanned repository is what a directory walk finds on disk before anything
decides whether that finding is new, moved, or already known — deliberately
a distinct shape from the repository record, because a scan result "has no
identity yet". The scan summary tallies what a scan changed
(added/moved/removed/unchanged/skipped) and renders that tally into the one
line a log statement or a progress window's closing message uses. None of
the three performs any I/O, networking, or persistence itself; they are the
shapes other components (a scanner, a reconciler, a database) pass to and
from each other.

