
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| config-status-001 | roster-no-provider-dependency, error-classification-reported, classification-http-error | Roster reads return 1 group, 1 site, 1 integration, 1 endpoint; the classification read fails with an error whose message is `deploy-projects/unconfigured 502` | `configure.sites`, `configure.endpoints`, `configure.integrations` each have length 1; `error` is an error whose message contains `502` |
| config-status-002 | unconfigured-sites-predicate, projects-from-server, counts | Endpoint `{ kind: "http", platform: null, deployProject: null, ignoreProjectWarning: false, isActive: true }`; classification `{ pending: [{ platform: "vercel", projectName: "p" }], addable: [], noDomain: [], unconfiguredSites: [] }` | `status.counts.total` is `2` (1 site + 1 project); `error` is falsy |
| config-status-003 | empty-until-both | Roster data loaded; classification still pending | `status` equals `EMPTY_STATUS`; `counts.total` is `0`; `isLoading` is `false`; `configure` is populated |
| config-status-004 | paused-fold | Endpoint `{ kind: "http", platform: null, deployProject: null, ignoreProjectWarning: false, isActive: false }`; classification with empty arrays | `status.unconfiguredSites` is empty; `counts.sites` is `0` |
| config-status-005 | paused-fold | Endpoint `{ kind: "http", platform: null, deployProject: null }` with `isActive` absent; classification with empty arrays | `status.unconfiguredSites` contains the endpoint; `counts.sites` is `1` |
| config-status-006 | endpoint-classification | Endpoints of kind `health`, `dns` and `custom`, all with `platform: null` | `status.unconfiguredSites` is empty |
| config-status-007 | endpoint-classification | Endpoint `{ kind: "http", platform: "vercel", deployProject: "web" }` | Not in `status.unconfiguredSites` |
| config-status-008 | by-platform-tally | `pending` platforms `["cloudflare-pages", "cloudflare", "vercel", null]` | `unmonitoredByPlatform` is `{ cloudflare: 2, vercel: 1, "": 1 }`; `counts.projects` is `4` |
| config-status-009 | no-domain-count, addable-from-server | `noDomain` has 3 entries, `addable` has 2 entries | `status.noDomainProjects` is `3`; `status.addableProjects` is the same 2-entry array |
| config-status-010 | error-precedence, error-single-slot | Roster read fails with error `"A"`; classification fails with error `"B"` | `error` is the error `"A"`; `configure` is not available; `status` equals `EMPTY_STATUS` |
| config-status-011 | roster-all-or-nothing | The integrations read fails; the other three reads resolve | `configure` is not available; `error` is the integrations-read failure |
| config-status-012 | invalidate-both, invalidate-result | Call `invalidateConfigQueries` on a cache holding both keys | Both `["configure-data"]` and `["configure-classification"]` are marked invalid and refetched if observed; the call resolves with no value |
| config-status-013 | enabled-false-no-fetch | Read Config Status with `{ enabled: false }` and no other consumer | No roster read and no classification read occur; `status` equals `EMPTY_STATUS` |
| config-status-014 | refetch-both | Call `refetch()` after both queries loaded | One more run of the four roster reads and one more classification read; the call resolves with both results |
| config-status-015 | classification-fetch | Classification query runs | The classification read is issued with no extra options; the request path is `/deploy-projects/unconfigured` (no `?fresh=1`) |
| config-status-016 | configure-data-key, classification-key | Read the exported constants | `CONFIGURE_DATA_KEY` deep-equals `["configure-data"]`; `CONFIGURE_CLASSIFICATION_KEY` deep-equals `["configure-classification"]` |
| config-status-017 | client-only | Load Configuration Status State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

