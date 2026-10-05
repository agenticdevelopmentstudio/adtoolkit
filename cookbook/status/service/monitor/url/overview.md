
`url.ts` (`packages/web/packages/status-server/src/monitor/url.ts`) is the status server's
shared home for two small, unrelated URL-string helpers used when building links for deploy
rows: `hostOf`, which extracts a URL's `host` for display or comparison, and
`projectPageUrl`, whose own doc comment states its purpose directly — "The platform PROJECT
page for a deploy URL — so clicking a project name always lands on the same place,
regardless of which specific deploy the row is about" — by collapsing a Vercel inspector URL
down to its team/project page and passing every other URL through unchanged. Both functions
are pure, synchronous, and defensive: each wraps its call to the `URL` constructor in a
`try`/`catch` and falls back to the raw input string on any parse failure, so neither
function ever throws.

`hostOf` is called from `sync.ts` — once to build the lower-cased live host a deploy row
stamps from its owning roster entry's URL, and once to compose the message a retired
monitor's removal is logged with — and from `routes/reads.ts`'s `ownerHostFor`, which
derives the live custom-domain host a deploy DTO reports, again lower-cased. `projectPageUrl`
is called from `deploy-view.ts`'s `deployLinks`, whose own comment says the derived
`sourceUrl` is "used by all three panes (active problems, resolved, activity) and the issue
recorder — so every row everywhere renders the same clickable link." Neither function has a
dedicated test file in the given source tree.

