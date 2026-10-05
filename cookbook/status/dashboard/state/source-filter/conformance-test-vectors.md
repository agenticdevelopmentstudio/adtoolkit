
| ID | Requirements | Input / Precondition | Action | Expected |
|----|-------------|----------------------|--------|----------|
| source-filter-001 | signature, default-all-selected | Fresh mount | Use Source Filter and read the first result | `sources` equals `{dns, http, glitchtip, vercel, cloudflare-pages, railway, crunchy}` (size 7), iterating in that order. The toggle operation is a function. |
| source-filter-002 | default-all-selected | Fresh mount | Check whether `sources` contains `"cloudflare-pages"` | `true` |
| source-filter-003 | toggle-flip, sources-immutability | Default state | Call the toggle operation with `"http"` | `sources` has 6 members and no `http`. It is a different set instance from before. |
| source-filter-004 | toggle-flip, toggle-order | State after source-filter-003 | Call the toggle operation with `"http"` | `sources` has 7 members and iterates `dns, glitchtip, vercel, cloudflare-pages, railway, crunchy, http`. |
| source-filter-005 | toggle-may-empty | Default state | Call the toggle operation once for each of the 7 sources | `sources` is an empty set (size 0). No error is thrown. |
| source-filter-006 | toggle-functional-update | Default state | Call the toggle operation with `"dns"` and with `"railway"` in one batch of updates | `sources` has 5 members, neither `dns` nor `railway`. |
| source-filter-007 | toggle-functional-update | Default state | Call the toggle operation with `"vercel"` twice in one batch | `sources` is back to all 7 members (the two toggles cancel). |
| source-filter-008 | seed-decoupled, lazy-seed | Default state | Call the toggle operation with `"dns"`, then read the fixed source list | The fixed source list still has 7 entries and includes `"dns"`. |
| source-filter-009 | per-instance-state | Two separate uses | Call the toggle operation with `"glitchtip"` in the first | The first use has 6 members. The second still has 7. |
| source-filter-010 | no-persistence | One use toggled to `{dns}` only | Stop using it and start again | `sources` is all 7 members again. No storage is ever touched. |
| source-filter-011 | toggle-identity-unstable | Any state | Force a re-render and compare the returned toggle operation with the previous one | Not reference-equal. `sources` IS reference-equal when no toggle occurred. |
| source-filter-012 | client-only | Source Filter is loaded in a server-only rendering context | Render it | It is unavailable there: the module is marked for client execution only |

