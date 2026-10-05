
Two pure functions that decide who claims a stretch of work and what rate it bills at. `resolve` maps a project root and branch to a claim (a repo row and a project, or Unassigned). `rateCents` walks the rate ladder for a segment that already knows its repo row. The ladder, most specific first: the repo row matching the root and branch, the repo row matching the root with an empty branch, the project default rate, then the global default rate from settings. The first non-null rate wins, and a rate of zero is a real rate.

