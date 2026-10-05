
- `ResearchFilters.q` / `.category` / `.tag` — caller-supplied search/filter
  strings for `markdownApi.list`, trimmed before use.
- `MarkdownListOptions.workspace` / `.noted` / `.doc` — caller-supplied
  workspace scope and per-corpus flags for `markdownApi.list`.
- `opts.workspace` — accepted by every other markdown.ts item operation
  (`get`, `create`, `update`, `remove`, `routeAvailable`, `publish`,
  `unpublish`, `categories`, `categoryTree`, `createCategory`, `tags`,
  `tagSet`).
- `ecosystemId` — a plain string parameter (not an `opts` object) accepted
  by `schemasApi.list` and `.create`, scoping which ecosystem's buckets are
  read or which ecosystem a new bucket belongs to.
- taxonomy.ts operations accept no scoping parameter at all; scoping is by
  ownership stamp on the backend side only.
- `PAGE_SIZE` (200) and `BASE` (`/api/content/markdown`) — compiled
  constants in markdown.ts, not configurable by a caller.
- `SCHEMAS` (`/api/bucket/buckets`) and `TABLES` (`/api/bucket/bucket-types`)
  — compiled constants in schemas.ts.
- `CATEGORIES`, `CATEGORY_EDGES`, `KEYWORDS` — compiled route-prefix
  constants in taxonomy.ts.
- the generic CRUD endpoint's roughly 500-row unpaginated cap on
  `schemasApi.list`/`.get` is a backend-side constant this client does not
  expose any way to configure.
- none of the four files read an environment variable or a runtime feature
  toggle.

