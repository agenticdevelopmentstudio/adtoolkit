
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `nowMs` (deriveBoard, deployProblems, endpointProblems, platformProblems, staleProdProblems, errorProblems, deriveActivity, reconcileBoardLedger's `opts.nowMs`) | `number` | `Date.now()` (only at `reconcileBoardLedger`'s boundary; every pure function requires it explicitly) | The derivation clock, epoch ms. Passed explicitly so every fold is pure and testable. |
| `index` / `RosterIndex` (deployProblems, staleProdProblems, deriveActivity's optional param) | `RosterIndex \| undefined` | freshly computed via `rosterTargets` when omitted | Lets a unit test call any rule directly with just facts; `deriveBoard` builds it once and threads it through. |
| `fromMs` (deriveActivity) | `number \| undefined` | `nowMs - ACTIVITY_WINDOW_MS` | The inclusive floor for an event's timestamp; a history page passes its own cursor-derived floor. |
| `cap` (deriveActivity) | `number \| undefined` | `MAX_ACTIVITY_ROWS` | How many rows the fold may return; a history page passes `Infinity`. |
| `opts.skipOnEmptyRoster` (reconcileBoardLedger) | `boolean` | `false` | Whether an empty roster read should skip the ledger sweep (config mutations that *caused* the emptiness leave this off; passive observers like `sync.ts` turn it on). |
| `config.probeIntervalSeconds` (readBoardFacts, via `StatusConfig`) | `number` (caller-supplied) | none — required | Read into `BoardFacts.probeIntervalMs` (× 1000) because the fold itself is pure and `config` is IO. |
| `config.glitchtipProjects` (readBoardFacts, via `StatusConfig`) | `readonly string[] \| null` (caller-supplied) | `null` (every project) | Carried into `BoardFacts.errorProjectAllowlist`, the one ownership gate `errorProblems` has in place of site ownership. |
| `config.alertWebhookUrl` (reconcileBoardLedger, via `StatusConfig`) | `string \| undefined` (caller-supplied) | none | Passed to `flushAlerts` after the ledger write. |
| `ACTIVITY_WINDOW_MS` (types.ts constant) | `number` | `86_400_000` (24 hours) | The Activity feed's window, and `ERROR_RECENT_MS`'s value. |
| `MAX_ACTIVITY_ROWS` (types.ts constant) | `number` | `300` | The live feed's row cap. |
| `MAX_ERROR_FACTS` (types.ts constant) | `number` | `100` | How many unresolved error groups `readBoardFacts` reads, matching the GlitchTip fetcher's own limit. |
| `DEGRADED_CONFIRM_MS` (types.ts constant) | `number` | `600_000` (10 minutes) | How long an endpoint must stay `degraded` before `endpointProblems` counts it. |
| `ACTIVITY_BASE_FACTS_CACHE_MS` (facts.ts constant) | `number` | `5_000` | How long `createActivityPageReader` may reuse a cached `readBoardFacts` result across scrolled pages. |
| `STUCK_DEPLOY_MS` (external constant, `../monitor/issue-sources`, consumed by `deployProblems`) | `number` | `1_800_000` (30 minutes) | How long a `building` deploy must run before it is judged `stuck`. |
| `PLATFORM_UNREACHABLE_POLLS` (external constant, `../monitor/issue-sources`, consumed by `platformProblems`) | `number` | `2` | Consecutive failed polls before a platform is judged unreachable. |
| `ERROR_JUDGED_LEVELS` (derive-problems.ts constant) | `Set<string>` | `{"error", "fatal"}` | The GlitchTip levels `errorProblems` counts as incidents. |

