
The git client is the toolkit's single door to git: a component that spawns
every git process the toolkit or an agent driving it will ever run, through
one bottleneck. It exposes four read-only verbs (status, current branch,
branches, worktrees) and three global-configuration verbs (read global
config, set global config, unset global config), resolves its own
configuration from three persisted settings on every call, records every
attempt — success or failure — in a redacted command log, and maps every
failure onto a closed four-case error outcome. It has no visual surface of
its own; every UI element that shows git state (a status badge, a branch
picker) is a consumer of this contract, not part of it.

