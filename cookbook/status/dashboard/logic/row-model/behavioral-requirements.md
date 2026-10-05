
### Row shape

- **row-tone-values**: Tone MUST be exactly one of `"good"`, `"bad"`, `"progress"`, `"neutral"`, `"stale"`.
- **row-required-fields**: A row MUST carry `key` (string), `source` (string), `platform` (string or null), `name` (string), `environment` (string or null), `statusWord` (string), `tone` (as above), `sha`, `commitUrl`, `message`, `detail` (each string or null), `at` (string), `sourceUrl` and `liveUrl` (each string or null).
- **row-optional-fields**: A row MAY carry `commitBody`, `lastCheckedAt`, `downSince`, `branch`, `errorText` (each string or null), and `statusCode` and `responseTimeMs` (each number or null); an absent optional field MUST be treated as not present by consumers ("undefined elsewhere so existing builders stay unchanged").
- **row-at-iso**: A row's `at` MUST be an ISO timestamp; it is "shown as a relative time and used for window filtering". This is a documented caller precondition, not validated here.
- **row-message-subject**: A row's `message` MUST hold only the commit subject line, while its `commitBody` holds the full commit message.

### The problem-to-row builder

- **problem-key**: The problem-to-row builder MUST set `key` to `"problem:"` followed by the problem's `target`.
- **problem-source-platform**: The problem-to-row builder MUST set both `source` and `platform` to the problem's `source`.
- **problem-status-word**: The problem-to-row builder MUST set `statusWord` to the state-label table's entry for the problem's `state` when that lookup is defined, and otherwise to the problem's `state` verbatim.
- **state-label-table**: The state-label table MUST map `down` to `"down"`, `degraded` to `"degraded"`, `failed` to `"deploy failed"`, `stuck` to `"deploy stuck"`, `stale` to `"deployment failed"`, `unreachable` to `"platform unreachable"` and `erroring` to `"app errors"`.
- **problem-tone-minor**: The problem-to-row builder MUST set `tone` to `"progress"` when the problem's `severity` is `"minor"`.
- **problem-tone-other**: The problem-to-row builder MUST set `tone` to `"bad"` when the problem's `severity` is `"major"` or `"critical"`; a problem row MUST NOT be `"good"`.
- **problem-at**: The problem-to-row builder MUST set `at` to the problem's `since`.
- **problem-down-since**: The problem-to-row builder MUST set `downSince` to the problem's `since` for every problem, whatever its source, so `downSince` equals `at` on every problem row.
- **problem-passthrough**: The problem-to-row builder MUST copy `name`, `environment`, `detail`, `sourceUrl`, `liveUrl`, `statusCode`, `branch` and `errorText` from the problem unchanged.
- **problem-no-probe-diagnostics**: The problem-to-row builder MUST leave `responseTimeMs` and `lastCheckedAt` absent.

### The activity-to-row builder

- **activity-key**: The activity-to-row builder MUST set `key` to the activity's `id` unchanged.
- **activity-platform**: The activity-to-row builder MUST set `platform` to the activity's `source`, or `null` when it is null or absent; it MUST NOT derive the platform by parsing the activity's `target`.
- **activity-source-fallback**: The activity-to-row builder MUST set `source` to the activity's `source` when non-null, and otherwise to the activity's `kind` (one of `"deploy"`, `"probe"` or `"platform"`).
- **activity-verb-tone**: The activity-to-row builder MUST set `statusWord` to the activity's `verb` and `tone` to the activity's `tone`, both verbatim; there is no phase table.
- **activity-passthrough**: The activity-to-row builder MUST copy `name`, `environment`, `detail`, `at`, `sourceUrl`, `liveUrl`, `branch` and `errorText` from the activity unchanged.
- **activity-no-diagnostics**: The activity-to-row builder MUST leave `statusCode`, `responseTimeMs`, `lastCheckedAt` and `downSince` absent.

### Commit fields (both builders)

- **commit-url**: The commit-URL function MUST return the literal text `"https://github.com/"` followed by the repository, then `"/commit/"`, then the hash, when both the repository and hash are non-empty strings.
- **commit-url-null**: The commit-URL function MUST return `null` when the repository or hash is null or the empty string.
- **commit-url-field**: Both builders MUST set `commitUrl` using the commit-URL function on their input's commit repository and hash.
- **sha-only-when-linked**: Both builders MUST set `sha` to the first 7 characters of the commit hash (via the short-sha function) only when `commitUrl` is non-null, and to `null` otherwise — "a bare, non-clickable hash is noise".
- **commit-message-subject**: Both builders MUST set `message` to the commit's first line (via the commit-first-line function): the text before the first line feed, capped at 200 characters, or `null` for a null or empty message; the message MUST be set even when `sha` is null.
- **commit-body-full**: Both builders MUST set `commitBody` to the input commit message unchanged.

### The display adapter

- **props-tone-color**: The display adapter MUST set `statusColor` from the tone: `good` to `var(--color-apt-green)`, `bad` to `var(--color-apt-red)`, `progress` to `var(--color-apt-gold)`, `neutral` to `var(--color-apt-gold)`, `stale` to `var(--color-apt-text-muted)`.
- **props-bold**: The display adapter MUST set `statusBold` to `true` only when the tone is `"bad"`.
- **props-verbatim-word**: The display adapter MUST set `statusWord` to the row's `statusWord` unchanged; it MUST NOT re-judge or demote a row based on its age.
- **props-time-label**: The display adapter MUST set `timeLabel` to the relative-time rendering of the row's `at` against the current time: `"just now"` under 60 seconds, then whole minutes as `"<n>m"` under 60 minutes, whole hours as `"<n>h"` under 24 hours, else whole days as `"<n>d"`.
- **props-platform**: The display adapter MUST set `platform` to the row's `platform`, converting `null` to absent.
- **props-passthrough**: The display adapter MUST copy `environment`, `name`, `sourceUrl` and `liveUrl` from the row unchanged.
- **props-no-copy**: The display adapter MUST NOT set `copyGetText` or any commit, detail or diagnostic field on its output.

### The search-text function

- **search-text-shape**: The search-text function MUST return `name`, `environment`, `statusWord`, `detail` and `commitBody` joined by single spaces, in that order, with a null or absent field contributing the empty string.
- **search-text-rendered-word**: The search-text function MUST use the same `statusWord` that the display adapter renders, so a filter matches the on-screen word.
- **search-text-excludes**: The search-text function MUST NOT include `source`, `platform`, `sha`, `message`, URLs or `branch`; the subject is searchable only through `commitBody`.

### Clipboard serialization

- **text-columns**: The row-text function MUST return exactly seven columns joined by a single tab character, in order: time label, environment badge, source label, name, status word, commit-or-detail, URL.
- **text-time**: The time column MUST be the relative-time rendering of the row's `at` against the current time.
- **text-env**: The environment column MUST be the environment-badge function's result for `environment` (`production` to `PROD`, `staging` to `STAG`, `testing` to `TEST`, any other value upper-cased) when `environment` is non-empty, and the empty string otherwise.
- **text-source**: The source column MUST be the source-label table's entry for `source` when `source` is a known issue-source identifier (see Issue Sources) (`dns` to `DNS`, `http` to `HTTP`, `glitchtip` to `GlitchTip`, `vercel` to `Vercel`, `cloudflare-pages` to `Cloudflare`, `railway` to `Railway`, `crunchy` to `Crunchy Bridge`), and `source` verbatim otherwise.
- **text-status**: The status column MUST be the row's `statusWord` verbatim.
- **text-commit-precedence**: The commit column MUST be the non-empty values of `sha` and `message` joined by one space when at least one is non-empty, else `detail` when non-empty, else the empty string.
- **text-url**: The URL column MUST be `liveUrl`, else `sourceUrl`, else the empty string; the column MUST be present even when empty.
- **text-field-escaping**: Row text MUST be produced with the same number of tab-separated fields on every row, taking `name`, `detail`, `statusWord`, `environment` and the URLs as given. The serializer neither escapes nor strips tab or newline characters inside a field, so such a character adds a column or splits the row; callers rely on the server supplying tab-free values.
- **rows-text**: The rows-text function MUST return each row's row-text joined by a single line feed, in input order, with no trailing line feed; an empty list MUST yield the empty string.

### Deploy demotion clock

- **unconfirmed-floor**: The unconfirmed floor MUST equal 600000 milliseconds (10 minutes).
- **unconfirmed-window**: The unconfirmed-window function MUST return the larger of the unconfirmed floor and five times the probe interval, treating an absent interval as 0.
- **dto-terminal-never-demoted**: The deploy-unconfirmed function MUST return `false` when the deploy's `status` is not in flight; only `"building"` and `"queued"` are in flight.
- **dto-clock-source**: The deploy-unconfirmed function MUST measure from the deploy's `phaseConfirmedAt`, falling back to `createdAt` when `phaseConfirmedAt` is null or absent.
- **dto-fail-closed**: The deploy-unconfirmed function MUST return `true` for an in-flight deploy whose clock string does not parse to a finite time.
- **dto-threshold**: The deploy-unconfirmed function MUST return `true` for an in-flight deploy when the current time minus the confirmed time is strictly greater than the unconfirmed window, and `false` when it is less than or equal.
- **row-never-clocked**: This logic MUST NOT apply a freshness clock to a row; an unconfirmed activity phase arrives already expired by the server (outside this logic) as verb `"unknown"`, tone `"stale"`.

### Module-wide

- **pure-synchronous**: Every exported function MUST be pure and synchronous: it MUST NOT read a clock (time is passed in as `nowMs`), perform I/O or mutate its inputs.
- **single-threaded**: This logic MUST run synchronously to completion; each call completes before another starts, so there is no ordering or locking contract.

