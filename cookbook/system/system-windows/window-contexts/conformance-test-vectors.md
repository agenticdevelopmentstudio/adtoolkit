
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| contexts-001 | park-on-attach | Windows 1 (Xcode) and 2 (Warp); create "Active" and "Inactive"; switch to "Active"; reset the mock; add window 2 to the inactive context | The mock records a move of window 2 |
| contexts-002 | park-on-attach | Window 1; create one context, no switch; reset; add window 1 to the context | No move recorded |
| contexts-003 | delete-active-context | Window 1 in "Active", window 2 in "Other"; switch to "Active"; reset; delete the active context | `activeContextID` is absent; set-frame recorded for window 1 and window 2 |
| contexts-004 | reconcile-stale-missing, has-stale-windows | Persist a snapshot with window 99 (Xcode); reload with live windows = [7 (Xcode)]; load state | The has-stale-windows flag is `true` |
| contexts-005 | reconcile-stale-recycled | Persist a snapshot with window 42 (Xcode); reload with live windows = [42 (Finder)]; load state | The has-stale-windows flag is `true` |
| contexts-006 | reconcile-stale-missing | Persist a snapshot with window 99 (Xcode); reload with live windows = [5 (Warp)]; load state | The has-stale-windows flag is `false`; the snapshot keeps `windowID` `99` |
| contexts-007 | store-load-state-missing | Fresh empty root; load state | A contexts state with `activeContextID` absent and `contextIDs` empty |
| contexts-008 | store-layout, store-save-all-content, store-json-format | Save all contexts `[A, B]` with active context `B.id`, into an empty root | `<root>/contexts/<A.id>.json` and `<B.id>.json` exist; `state.json` decodes to `activeContextID == B.id`, `contextIDs == [A.id, B.id]`; the JSON keys appear sorted; `<root>/.lock` exists |
| contexts-009 | store-load-all-skips, store-load-all-order | After contexts-008, overwrite `<A.id>.json` with `not json`; load all contexts | Returns `[B]`; no error thrown |
| contexts-010 | store-load-state-errors | Write `{` to `state.json`; load state | Throws `decodingFailed` with the `state.json` path |
| contexts-011 | store-load-context-missing | Load a context with a freshly generated `id`, on an empty root | Throws `contextNotFound(id:)` with that ID |
| contexts-012 | store-list-files | List context files where `contexts/` holds `<valid uuid>.json`, `notes.txt`, `bad.json` | Returns exactly the one valid UUID |
| contexts-013 | store-delete-context | Delete a context with a freshly generated `id`, for a file that does not exist | Succeeds with no error |
| contexts-014 | store-save-all-no-prune | Save all contexts `[A, B]` with no active context, then save all contexts `[B]` with no active context | `<A.id>.json` still exists; `state.json` lists only `B.id` |
| contexts-015 | settings-lenient-decode | Decode `{}` as the contexts settings | `launchAtLogin == false`, `reconcileBehavior == prompt`, `hiddenApps == []`, `showAppInDock == false` |
| contexts-016 | settings-typed-decode | Decode `{"launchAtLogin": "yes"}` | Throws a decoding error |
| contexts-017 | reconcile-behavior-cases | The raw values of the complete reconcile-behavior list, in order | `["prompt", "auto", "ignore"]` |
| contexts-018 | add-window-duplicate | Window 1 in context A; add window 1 to context B | Throws `windowAlreadyAssigned(windowID: 1, contextName: "A")` |
| contexts-019 | add-window-refresh | Window 1 in A; change the mock's frame for window 1; add window 1 to context A | A still has one snapshot; its `savedFrame` equals the new frame |
| contexts-020 | add-window-errors | Add window 555 to context A, with no window 555 live | Throws `windowNotFound(windowID: 555)` |
| contexts-021 | delete-context-missing | Switch to a context with a freshly generated `id` | Throws `contextNotFound`; no move or set-frame recorded |
| contexts-022 | switch-same-context | Active A holding window 1; reset; switch to context A | Set-frame recorded for window 1; no move recorded; no error |
| contexts-023 | switch-restore-target, switch-focus, switch-commit | A holds window 1, B holds window 2, A active; switch to context B | Window 1 moved; window 2 set to its saved frame; focus recorded for window 2; `activeContextID == B.id` |
| contexts-024 | parking-position | Single screen with `minX == 0`; park window 1 whose saved frame y is 50 | Move to (−30000, 50) |
| contexts-025 | frame-capture-guard | Active A with window 1 whose live frame x is −30000 (off every screen); switch to context B | Window 1's `savedFrame` is unchanged |
| contexts-026 | remove-window | Window 2 in inactive B while A is active; remove window 2 | Returns the snapshot; set-frame recorded for window 2 to its saved frame |
| contexts-027 | remove-window | Remove window 777, with no snapshot carrying it | Throws `windowNotInAnyContext(windowID: 777)` |
| contexts-028 | set-last-focused | No active context; set the last-focused window to 1 | Returns without error; no persist |
| contexts-029 | launch-rematching | All snapshots live; perform launch re-matching | Returns no value |
| contexts-030 | assign-to-snapshot | Assign window 1 to a snapshot with a freshly generated `id` in context A | Throws `windowNotInAnyContext(windowID: 1)` |
| contexts-031 | assign-batch | Assign windows to snapshots in a batch, with an empty list | Returns 0; no windows enumerated |
| contexts-032 | mark-app-dormant | Live snapshot with `app == "Xcode"`; mark app "xcode"'s windows dormant | Returns 0; snapshot still live |
| contexts-033 | rematch-app | Dormant Xcode snapshot; live Xcode window scoring 80 against it; re-match dormant windows for app "XCODE" | Returns 1; snapshot's `windowID` is the window's ID |
| contexts-034 | new-window-autoassign | Dormant snapshot; new window scoring 79 | Checking the new window for auto-assignment returns no value; snapshot stays dormant |
| contexts-035 | custom-rule-autoassign | Rule `autoAssign: true`, app "Safari", target "docs"; context named "Docs"; new Safari window whose title the rule matches | Returns the "Docs" context ID; the context gains a snapshot for the window |
| contexts-036 | rules-write-first | Custom heuristic store whose save throws; add custom heuristic rule `r` | Throws; `customHeuristicRules` unchanged |
| contexts-037 | model-add-frontmost | Model with no active context; add the frontmost window | Returns `false`; `lastError == "No active context. Switch to a context first."` |
| contexts-038 | model-cycle | Contexts [A, B, C], active C; switch to the next context | Active becomes A |
| contexts-039 | model-hidden-apps | `hiddenApps` is `["Zed"]`; add hidden app "Arc"; add hidden app "Arc" again | `hiddenApps == ["Arc", "Zed"]` |
| contexts-040 | model-unmatched-items | One dormant snapshot; live unassigned windows scoring 30, 0, 90 | One item; candidates scored `[90, 30]` |
| contexts-041 | persist-error-wrap, memory-ahead-of-disk | Make `<root>/contexts` read-only; rename context A to "X" | Throws `persistenceFailed`; `contexts` shows A named "X" |
| contexts-042 | model-test-environment | Construct the model with `isTestEnvironment: true` | `notificationsEnabled == false`; `observationEnabled == false`; loading state on an empty store leaves `contexts` empty |

