
`format.ts` (`packages/web/packages/status-server/src/monitor/format.ts`) is the status
server's single source for two small pieces of commit-display formatting that its own
header comment says were "otherwise copy-pasted across the fetchers and the row
builders": truncating a commit sha to GitHub's 7-character short form, and pulling the
display subject out of a commit message. It exports three pure, synchronous functions —
`shortSha`, `commitFirstLine`, and `commitFullMessage` — with no class, no shared state,
and no I/O. `shortSha` is called from `webhook-events.ts`, `fetch-vercel.ts`,
`fetch-vercel-projects.ts`, `fetch-railway.ts`, and `fetch-cloudflare.ts` to populate a
deploy row's `commitHash` field; `commitFullMessage` is called from the same five files to
populate `commitMessage`; `commitFirstLine` is called from `derive-activity.ts` and
`derive-problems.ts` to derive the one-line `detail` string a board activity or problem
entry shows, from a deploy's already-full `commitMessage`. Per the module's own doc
comment, a commit message is shaped `"subject\n\nbody"`, and the module's job is to let a
row show only the subject (`commitFirstLine`) while a details pane can still show the
whole thing (`commitFullMessage`), rather than each call site re-deriving either from
scratch.

