
A project checkout is the value the project controller opens one tab group
per: either a repository's own checkout or one of its linked git worktrees.
It is a small, comparable, concurrency-safe value holding a symlink-resolved
`directory`, an optional `branch` name, and an `isMain` flag, plus two
derived values — a stable, path-derived `identifier` and a `displayName`
that prefers the branch name. One factory operation projects a list of
worktree records (as parsed from `git worktree list --porcelain` output)
into the subset of checkout values that can actually be opened in a tab.

