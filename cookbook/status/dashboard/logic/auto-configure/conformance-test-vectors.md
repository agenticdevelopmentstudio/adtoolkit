
Derived from `src/lib/auto-configure.test.ts` unless noted.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| autocfg-001 | endpoint-projection | Constructing the port adapter over a fake backing implementation whose endpoint list returns one endpoint view `{id:"e1", siteId:"s1", url:"https://a.com", kind:"frontend", environment:"production", platform:"vercel", deployProject:"p", ignoreProjectWarning:false, expectedStatus:200, isActive:true, …}` | the port's endpoint-list operation resolves to exactly `[{id:"e1", siteId:"s1", url:"https://a.com", kind:"frontend", environment:"production", platform:"vercel", deployProject:"p", ignoreProjectWarning:false}]` |
| autocfg-002 | opt-out-fold | Three endpoint views: `ignored` (`ignoreProjectWarning:true`), `paused` (`isActive:false`), `live` (neither) | Projected flags: `ignored → true`, `paused → true`, `live → false` |
| autocfg-003 | site-projection | The port's site-list operation given a backing site view `{id:"s1", slug:"alpha", groupId:"g1", name:"Alpha", extra:"ignored"}` | resolves to `[{id:"s1", slug:"alpha", groupId:"g1"}]` |
| autocfg-004 | match-only | No endpoints or sites. Running a match over one project `{platform:"vercel", projectName:"help-production", domain:"agenticdeveloperhelp.com"}` with a supplied port | `createSite` and `createEndpoint` are never called. `added === 0`. `skipped[0]` is `{project:"help-production", reason}` with `reason` containing `no site monitors this domain` |
| autocfg-005 | added-is-count, skipped-flattened, match-write-shape | One endpoint `e1` on `https://a.com` (production). Running a match over two projects, `a-production` (a.com) and `b-production` (b.com) | `added === 1`. `skipped` equals `[{project:"b-production", reason:<string>}]`. One update-endpoint call for `e1` |
| autocfg-006 | client-required | Running a match over an empty project list with neither a port nor a client supplied | Rejects with `Error("runMatch: opts.client is required when opts.api is not supplied")` |
| autocfg-007 | injected-port-precedence | Running a match with both a supplied port and an explicitly absent client | Resolves normally, and the supplied port's operations are the ones called |
| autocfg-008 | detail-empty | Each detail-block builder called with an absent input, then with an empty list | Each returns `""` |
| autocfg-009 | skip-header, detail-row-format, detail-leading-separator | The skip-detail block builder given two skip rows: `{project:"p1", reason:"r1"}, {project:"p2", reason:"r2"}` | `"\n\nLeft alone:\n• p1: r1\n• p2: r2"` |
| autocfg-010 | detail-no-remainder | The skip-detail block builder given exactly 5 rows | Splitting on `"\n• "` yields 6 parts, and the output does not contain `more` |
| autocfg-011 | detail-cap, detail-remainder | The skip-detail block builder given 7 rows p1..p7 | Contains `• p5: r5`, does not contain `• p6: r6`, and contains `…and 2 more` |
| autocfg-012 | note-header | The note-detail block builder given two note rows: `{project:"p1", note:"n1"}, {project:"p2", note:"n2"}` | `"\n\nAlso:\n• p1: n1\n• p2: n2"` |
| autocfg-013 | detail-line-limit | The note-detail block builder given 7 rows | Splitting on `"\n• "` yields 6 parts, and the output contains `…and 2 more` |
| autocfg-014 | per-project-resilience | A port whose update-endpoint operation rejects with `Error("boom")` for the first matching project, and a second project that matches normally | First project is in `skipped` with reason `boom`. `added === 1` for the second |
| autocfg-015 | snapshot-failure-rejects | A port whose endpoint-list operation rejects with `Error("down")` | The match operation rejects with `down`, and no update-endpoint call is made |
| autocfg-016 | progress-forwarded | Running a match over 2 projects with a progress callback observed | Callback called with `(1, 2)` and then `(2, 2)` |
| autocfg-017 | notes-flattened | An engine plan for project `x` that wires an endpoint taking over from a retired project `old` on platform `vercel` | `notes` equals `[{project:"x", note:"took over the monitor wired to old, which vercel no longer has"}]`, and `added === 1` |

