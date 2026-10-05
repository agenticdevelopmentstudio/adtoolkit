
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| invitation-panes-001 | shows-loading-placeholder | Render any of the three panes with the loading flag true | Output is the "Loading…" text; the list-with-details layout is not rendered |
| invitation-panes-002 | delegates-list-rendering | Render the Requests pane with the loading flag false/absent and a set of rows | The list-with-details layout receives the Requests columns, empty label "No invitation requests.", storage key "adm-inv-requests" |
| invitation-panes-003 | delegates-list-rendering | Render the Pending Users pane with rows | The list-with-details layout receives the Pending Users columns, empty label "No pending users.", storage key "adm-inv-pending" |
| invitation-panes-004 | delegates-list-rendering | Render the Invites pane with rows | The list-with-details layout receives the Invites columns, empty label "No invites sent.", storage key "adm-inv-invites" |
| invitation-panes-005 | forwards-param-key | Render any pane with a deep-linking selection key of "sel" | The list-with-details layout receives that same selection key |
| invitation-panes-006 | forwards-delete-callback | Confirm delete on any pane with rows selected | The pane's delete callback is invoked with the selected ids |
| invitation-panes-007 | notes-action-requires-selection | Render any pane with 0 rows selected | The "Admin notes" action requires a non-empty selection (delegated disabling per the list-with-details layout) |
| invitation-panes-008 | notes-action-sets-first-selected-id | Activate "Admin notes" with rows "a","b" selected | The admin-notes target id becomes "a" |
| invitation-panes-009 | notes-action-sets-first-selected-id | Activate "Admin notes" with no rows selected | The admin-notes target id becomes unset |
| invitation-panes-010 | gates-notes-modal-on-existing-row | Set the admin-notes target id to an id present in the pane's rows | The notes modal is shown open |
| invitation-panes-011 | gates-notes-modal-on-existing-row | Set the admin-notes target id to an id, then that row leaves the pane's rows | The notes modal is shown closed |
| invitation-panes-012 | resets-notes-id-on-modal-close | Close the notes modal | The admin-notes target id becomes unset |
| invitation-panes-013 | passes-required-aria-label | Render the Pending Users pane | The list-with-details layout receives the accessible name "Pending users" |
| invitation-panes-014 | requests-and-pending-show-source-and-note | Select a request row with source "web", note "urgent" | Detail shows "Source: web" and "Note to the team: urgent" above the notes/history content |
| invitation-panes-015 | invites-detail-is-notes-only | Select an invite row | Detail is exactly the notes/history content; no "Source:"/"Note:" lines appear |
| invitation-panes-016 | send-action-requires-selection | Render the Pending Users pane with 0 rows selected | "Send invitation" action requires a non-empty selection |
| invitation-panes-017 | send-seed-filters-selected-rows | Activate Send with ids "u1","u2" | The seed is built only from the rows whose id is u1 or u2 |
| invitation-panes-018 | send-seed-collects-non-empty-emails | Selected rows have emails "a@x.io", "" | Seed emails is ["a@x.io"] |
| invitation-panes-019 | send-seed-collects-non-empty-phones | Selected rows have phones "", "+15550100" | Seed phones is ["+15550100"] |
| invitation-panes-020 | send-seed-carries-selected-ids | Activate Send with ids "u1","u2" | Seed ids is exactly ["u1","u2"] |
| invitation-panes-021 | send-action-opens-modal | Activate "Send invitation" | The send-invitation modal opens |
| invitation-panes-022 | remounts-send-modal-on-reseed | Open Send for selection A (ids ["u1"], email a@x.io), close, open Send for selection B with different contacts (ids ["u2"], email b@x.io) | The send-invitation modal is treated as a fresh instance between the two opens |
| invitation-panes-023 | closes-send-modal-only-on-resolve | Caller's send callback's promise resolves | The send-invitation modal closes |
| invitation-panes-024 | keeps-send-modal-open-on-reject | Caller's send callback's promise rejects | The send-invitation modal remains open; no error is thrown out of the handler |
| invitation-panes-025 | add-action-has-divider | Inspect the "Add users" action | It renders with a divider before it |
| invitation-panes-026 | add-action-opens-modal | Activate "Add users" | The add-users modal opens |
| invitation-panes-027 | forwards-onadd | The add-users modal invokes its add handling with a list of users | The pane's add callback is called with that same list |
| invitation-panes-028 | forwards-send-busy | Render the Pending Users pane with its send-busy indicator true | The send-invitation modal receives a busy state of true |
| invitation-panes-029 | forwards-add-busy | Render the Pending Users pane with its add-busy indicator true | The add-users modal receives a busy state of true |
| invitation-panes-030 | shows-delete-confirm-copy | Inspect the Requests pane's delete-confirmation copy | title "Delete requests?", description "This removes the selected invitation requests." |
| invitation-panes-031 | shows-delete-confirm-copy | Inspect the Pending Users pane's delete-confirmation copy | title "Delete pending users?", description "This removes the selected pending users." |
| invitation-panes-032 | shows-delete-confirm-copy | Inspect the Invites pane's delete-confirmation copy | title "Delete invites?", description "This removes the selected sent invites." |
| invitation-panes-033 | requests-and-pending-show-source-and-note | Select a pending-user row with lastSource "referral", lastNote "thanks" | Detail shows "Source: referral" and "Note from user: thanks" above the notes/history content |
| invitation-panes-034 | pending-null-dates-render-dash | Render the Pending Users pane with a row whose "Last request" and "Last invite" values are both null | Both columns render "—" |

