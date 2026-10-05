
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | shared-core-both-menus, reference-group-removed | render marketing vs workspace menu | identical Hub section; no "Reference" group in either |
| T2 | top-section-logged-out | unauthenticated | Login + Sign up above Hub; no Home/Recents |
| T3 | top-section-logged-in, in-hub-rows-authed-only | authenticated | Home/Workspaces/Recents present; News/Ecosystems/Personas/Organizations/Research visible; hidden when logged out |
| T4 | inline-subitem-kind, hub-subitems-inventory | render Hub | sub-items rendered indented, in the specified order |
| T5 | row-icon-label-description, icon-reuse-existing | render any row | icon precedes label; Community shows `Users`, Narratives shows `ScrollText` |
| T6 | workspaces-flyout | open Workspaces with 3 workspaces | flyout lists all 3, labelled + navigating to each home |
| T7 | recents-flyout, recents-empty-hidden | 0 recents / 3 recents | entry hidden at 0; lists 3 most-recent-first otherwise |
| T8 | recents-settle-only | drill list→detail→leaf within the settle window, stop at leaf | only the leaf is recorded |
| T9 | recents-dedupe-cap | record 11 distinct, then re-record #1 | 10 kept, oldest evicted; #1 moves to front |
| T10 | recents-deep-link | click a recent | navigates to that view's deep URL |
| T11 | recents-persist-local | record, reload | recents survive reload (same device) |
| T12 | keyboard-accessible | open, arrow, flyout, Escape | selection moves, flyout opens/closes, focus returns to trigger |

