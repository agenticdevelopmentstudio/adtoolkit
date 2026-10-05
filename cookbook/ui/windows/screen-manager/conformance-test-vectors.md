
Derived from the reference test suite. Screens: B = uuid `BUILTIN`, name
`Built-in`, frame (0,0,1920,1080), main; E = uuid `EXTERNAL`, name `LG
Monitor`, frame (1920,0,2560,1440).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| screen-manager-001 | set-identity-order-independent, set-identity-derivation | Compute the set identity of [B, E] and of [E, B] | Equal strings (`BUILTIN+EXTERNAL`) |
| screen-manager-002 | identity-resolution-independent, identity-component-uuid | Compute the set identity of [B] and of B at 2560×1440 (same UUID) | Equal |
| screen-manager-003 | set-identity-derivation | Compute the set identity of [B] and of [B, E] | Not equal |
| screen-manager-004 | init-current-set-id, init-upsert-persist, upsert-new, current-set-lookup | Init with [B], clock fixed at t=1,000,000 | Known-sets count is 1; the current set's id equals the current set identity; first-seen equals last-seen equals t; one snapshot with display UUID `BUILTIN`; storage holds exactly that id |
| screen-manager-005 | touch-in-memory-every-call, upsert-existing | Init at t; clock → t+3600; touch the current set | First-seen equals t; last-seen equals t+3600 |
| screen-manager-006 | init-load-and-prune | Storage has `STALE` (last-seen now−200 days) and `FRESH` (last-seen now−1 day); default maximum age; init with [B] | Known-set-ids lacks `STALE`, contains `FRESH` and the current set identity |
| screen-manager-007 | classify-no-change | Classify from [B,E] to [B,E] | No change |
| screen-manager-008 | classify-resolution | [B] → B at 2560×1440 | A resolution change |
| screen-manager-009 | classify-arrangement | [B,E] → [B, E at x = −2560] | An arrangement change |
| screen-manager-010 | classify-set-change-first | [B] → [B,E] | A screen-set change carrying the previous identity (identity of [B]) and current identity (identity of [B,E]) |
| screen-manager-011 | identity-component-name-fallback, classify-resolution | UUID-less `Dock HDMI` 1920×1080 → 2560×1440 | Identities equal; a resolution change |
| screen-manager-012 | classify-no-pairing, classify-no-change | Two UUID-less `Twin` screens at x=0 and x=1920, unchanged | No change |
| screen-manager-013 | classify-no-pairing, classify-arrangement | Twins: second moves from x=1920 to x=3840 | An arrangement change |
| screen-manager-014 | process-real-change, observer-delivery-after-update, known-sets-order | Init [B]; add observer; provider → [B,E]; process the screen change | Observer receives exactly one screen-set change (solo to docked); the current set identity read inside the handler equals docked; storage ids = {solo, docked}; the most recent known-sets entry's id equals docked |
| screen-manager-015 | process-spurious-silent | Init [B]; add observer; process a notification with no screen change | Observer not called |
| screen-manager-016 | remove-observer | Add then remove observer; provider → [B,E]; process the screen change | Observer not called |
| screen-manager-017 | reconcile-refresh, touch-persist-throttle | Init [B]; provider → [B,E]; touch the current set (no notification) | Current set identity equals identity of [B,E]; storage contains the docked set |
| screen-manager-018 | reconcile-no-notify, process-diff-baseline | Vector 017 with an observer, then process the screen change | No call after the touch; after processing, exactly one screen-set change (solo to docked) |
| screen-manager-019 | reconcile-cheap-guard, upsert-existing | Init [B,E]; touch the current set 5 times | Current set identity unchanged; exactly one known-sets entry with that id |
| screen-manager-020 | returning-set-keeps-first-seen | Init [B] at t; t+3600 → [B,E] processed; t+7200 → [B] processed | Current set identity equals solo; first-seen equals t; last-seen equals t+7200 |
| screen-manager-021 | touch-persist-throttle | Init at t; touch at t (persists); change screens so screens differ; touch at t+30 | Second touch updates memory but makes no persist call; a touch at t+60 persists |
| screen-manager-022 | notification-rearm-idempotent | Call start-observing three times; post a screen-parameter-change notification after a set change | Observer called exactly once |
| screen-manager-023 | upsert-prune-on-persist | Storage set last-seen exactly the maximum age before the current time; init | Set is kept |
| screen-manager-024 | classify-visible-frame-counts | Same frames; one screen's visible frame height drops by 80 | A resolution change |
| screen-manager-025 | storage-settings-blob | The settings-backed storage over an empty store; load the sets | `[]` |

Vectors 021–025 are not in the reference test suite; they are derived from
the touch operation, the observation-start operation, the pruning function,
the classification function and the storage default value respectively.

