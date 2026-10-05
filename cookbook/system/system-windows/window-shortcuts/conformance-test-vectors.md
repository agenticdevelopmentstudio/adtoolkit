
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wms-001 | index-shortcut-count | Read the switch-by-index list's length | `9` |
| wms-002 | all-shortcuts-list | Read the full shortcut list's length | `14` |
| wms-003 | unique-names | Map the full shortcut list to identifiers; compare the count with the count of the set of them | Counts equal |
| wms-004 | index-shortcut-order, stable-raw-values | Map the switch-by-index list to identifiers | `["switchToContext1", …, "switchToContext9"]` in that order |
| wms-005 | every-name-has-default | For each name in the full shortcut list, read its default shortcut | Non-nil for all fourteen |
| wms-006 | action-shortcut-names, default-picker-chord, all-shortcuts-list | Read `contextPicker`'s identifier, its default shortcut, and whether the full shortcut list contains it | `"contextPicker"`, non-nil, `true` |
| wms-007 | default-index-chords | Read `switchToContext3`'s default shortcut | Key `3`, modifiers exactly the scheme's modifier pair |
| wms-008 | default-add-chord, default-remove-chord, default-next-chord, default-previous-chord | Read the defaults of `addWindow`, `removeWindow`, `nextContext`, `previousContext` | A, X, N, P respectively, each with exactly the scheme's modifier pair |
| wms-009 | all-shortcuts-list | Read elements 9…13 of the full shortcut list | `addWindow`, `removeWindow`, `nextContext`, `previousContext`, `contextPicker` |
| wms-010 | register-on-init, dispatch-index | Model with contexts `[A, B, C]`; construct the manager; fire key-down for `switchToContext2` | The context-switch action is called once, targeting `B`'s id |
| wms-011 | index-out-of-range-noop | Model with 2 contexts; fire key-down for `switchToContext5` | No model action called; no error set |
| wms-012 | index-out-of-range-noop | Model with 0 contexts; fire key-down for `switchToContext1` | No model action called |
| wms-013 | index-read-at-fire-time | Construct the manager with 1 context; append a second context; fire `switchToContext2` | The context-switch action is called, targeting the new context's id |
| wms-014 | dispatch-add, result-ignored | Fire key-down for `addWindow` | The add-frontmost-window action is called once; the manager takes no further action on its result |
| wms-015 | dispatch-remove | Fire key-down for `removeWindow` | The remove-frontmost-window action is called once |
| wms-016 | dispatch-next | Fire key-down for `nextContext` | The switch-to-next-context action is called once |
| wms-017 | dispatch-previous | Fire key-down for `previousContext` | The switch-to-previous-context action is called once |
| wms-018 | dispatch-picker | Fire key-down for `contextPicker` twice | The toggle-context-picker action is called twice (picker visibility returns to its starting value) |
| wms-019 | reserve-external | Construct the manager; ask the key-command registry about the availability of the scheme's modifier pair plus A for an unrelated command id | Unavailable, reported as taken by window contexts |
| wms-020 | reservation-follows-customization | Construct the manager; customize `addWindow` to the scheme's modifier pair plus Z; query availability of that chord and of the scheme's modifier pair plus A for an unrelated command | Z is unavailable, reported as taken by window contexts; A is not refused by the window-contexts reservation |
| wms-021 | weak-handler-capture, no-unregister-on-release | Construct a manager, drop every reference to it, fire key-down for `addWindow` | No model action called; the chord remains reserved in the registry |
| wms-022 | init-log | Construct the manager | One info-level log confirming initialization and handler registration, in the manager's own logging category |

