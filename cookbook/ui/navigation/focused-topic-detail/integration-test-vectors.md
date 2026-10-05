
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | editable-identifier, surface-identifier-collision | rename Identifier to a taken rdid | inline collision (409) error; UUID unchanged |
| T2 | editable-identifier | rename Identifier to a free rdid | `PATCH /registry/identifiers/{oldRdid}` called; route/`lastId` refresh to the new rdid |
| T3 | two-step-delete, typed-confirm-exact | Delete → Yes → type partial rdid | `Permanently Delete` disabled until exact, case-sensitive match |
| T4 | delete-navigates-to-all, clear-laststate-on-delete | confirm delete succeeds | API called; `lastId` cleared; navigates to All |
| T5 | new-action-in-popup | open popup → New {Entity}… | Create dialog opens (not a navigation) |
| T6 | all-view-filter | type a query in All filter | list narrows by name/identifier; no-match shows empty state |
| T7 | all-view-toggle, persist-view-mode | switch to list, reload | list mode persists via `…:viewMode` |
| T8 | resume-last-selected | enter bare base path with a live `lastId` | focuses that entity; stale/missing → All |
| T9 | delete-navigates-to-all | confirm delete → API call rejects | inline error text shown; dialog stays open; `lastId` unchanged |
| T10 | validate-identifier-format | type an uppercase or malformed identifier | value is lowercased; a malformed value blocks submit with an inline format error |
| T11 | danger-zone-collapsed-neutral | load the entity pane | Danger Zone renders collapsed, neutral border/title, `apt-gold` glyph; opening it applies the `apt-red` title/border |
| T12 | first-topic-is-entity | load any FTD route's topic list | first topic is the entity itself, labelled `Entity`, no divider above it |
| T13 | no-action-bar | load any FTD route | no full-width New/Delete action bar renders above the grid |
| T14 | selector-popup-switches-focus | choose a different entity (or All) in the selector popup | view navigates to `{basePath}/{id}/{topic}` (or `{basePath}/all`) for the chosen item |
| T15 | resolve-after-list-load | enter the bare base path before the entity list has loaded | normal loading state shows; `lastId` resolution runs only after the list resolves |
| T16 | surface-states | All view loading / no entities / filter-no-match / delete error / identifier collision | each condition shows its own state (spinner, empty copy, "No {entities} match…", inline delete error, inline collision error) |
| T17 | accessibility | open a delete dialog; inspect the All-view toggle | dialog has `role="dialog"` with focus trapped and restored on close; toggle carries `role="radiogroup"` and `aria-label="View as"` |
| T18 | rename-unknown-rdid-404 | `PATCH` with an old rdid that is no longer registered | 404 response surfaces as an inline error |
| T19 | identifier-availability-check | type a candidate identifier | inline availability hint reflects `GET …/exists` before submit |
| T20 | warning-copy-article-agreement | `Entity` starting with a vowel vs. a consonant | step-1 copy reads "an" vs. "a" correctly |
| T21 | explicit-all-precedence | navigate to `{basePath}/all` while a live `lastId` is set | All view renders regardless of the stored id |

