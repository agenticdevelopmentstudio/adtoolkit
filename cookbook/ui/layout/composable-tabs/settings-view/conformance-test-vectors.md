
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cts-settings-vc-001 | constructs-topic-list-from-closures | Construct with `isEdgeEnabled`/`setEdgeEnabled` closures | A topic-list child exists whose Tabs panel was constructed with the same two closures |
| cts-settings-vc-003 | tags-window-background-role | Load the component | The root view's background is the `.windowBackground` theme role |
| cts-settings-vc-004 | identifies-sheet-root | Load the component | The root view's accessibility identifier equals `"project-window.project-settings"` |
| cts-settings-vc-005 | embeds-topic-list-as-child | Load the component | The topic list appears among the component's child elements, and its view is a subview of the root view |
| cts-settings-vc-006 | pins-panel-to-top-leading-trailing | Load the component | Constraints exist pinning the topic list's view top/leading/trailing to the container; no constraint pins its bottom to the container |
| cts-settings-vc-007 | renders-done-button | Load the component | A subview exists titled "Done" with a rounded appearance |
| cts-settings-vc-008 | binds-return-key-to-done | Load the component | The Done button's activation shortcut is the Return key |
| cts-settings-vc-009 | identifies-done-button | Load the component | The Done button's accessibility identifier equals `"project-window.project-settings.done"` |
| cts-settings-vc-010 | lays-out-done-button-offsets | Load the component, resolve constraints | Done button's top is 12pt below the topic list's bottom; container's trailing is 20pt beyond Done's trailing; container's bottom is 16pt beyond Done's bottom |
| cts-settings-vc-011 | dismisses-on-done | Click the Done button | The sheet is dismissed (the sheet closes) |
| cts-settings-vc-012 | applies-changes-live | Toggle an edge, then inspect a `setEdgeEnabled` spy's call order relative to Done/dismiss | The `setEdgeEnabled` spy was already called at the moment of the toggle, before any Done-button click or dismissal occurs |
| cts-settings-vc-013 | sizes-preferred-content | Load the component | The preferred content area is 760×520pt |
| cts-settings-vc-014 | titles-sidebar-project | Construct the topic list | Its sidebar title equals "Project" |
| cts-settings-vc-015 | widens-detail-pane | Read the topic list's detail-pane minimum width | Returns `420` |
| cts-settings-vc-016 | fixes-sidebar-width | Read the topic list's content-sized-sidebar setting | Returns `true` |
| cts-settings-vc-017 | presents-help-as-popover | Construct the topic list, load its view | Help is presented through a popover-style presenter |
| cts-settings-vc-018 | registers-two-panels-in-order | Load the topic list | Panel at index 0 is the Tabs panel, index 1 is the Spacing panel, and the selected panel is index 0 |
| cts-settings-vc-020 | lists-edges-in-reading-order | Load the Tabs panel | Toggles appear in the group in the order Top, Right, Bottom, Left |
| cts-settings-vc-021 | labels-tabs-descriptor | Construct the Tabs panel | Its descriptor's title equals "Tabs", with an icon representing a grid of tab bars |
| cts-settings-vc-022 | groups-edge-checkboxes | Load the Tabs panel | All four toggles are rows of one group titled "Tab Bars"; no second group exists |
| cts-settings-vc-023 | reflects-initial-edge-state | Construct the Tabs panel with `isEdgeEnabled` returning `true` for `.top` and `false` for the rest | Only the Top toggle's initial state is on |
| cts-settings-vc-024 | identifies-edge-checkboxes | Load the Tabs panel | The Left toggle's accessibility identifier equals `"project-settings.tabs.left"` (and correspondingly for the other three edges) |
| cts-settings-vc-025 | themes-checkbox-title-color | Fire a theme change after loading | Each toggle's title is rebuilt with the primary-text color and body text style |
| cts-settings-vc-026 | commits-edge-toggle | Click the Right toggle to turn it on | `setEdgeEnabled(.right, true)` is called |
| cts-settings-vc-027 | reverts-checkbox-to-authoritative-state | Click the last enabled edge's toggle to turn it off, with `isEdgeEnabled` continuing to report `true` for that edge after the call | The toggle's state ends the handler on, not off |
| cts-settings-vc-028 | guards-invalid-checkbox-tag | Invoke the toggle handler with a sender whose index maps to no edge | `setEdgeEnabled` is not called; the handler returns with no effect |
| cts-settings-vc-029 | labels-spacing-descriptor | Construct the Spacing panel | Its descriptor's title equals "Spacing", with an icon representing a 2×2 grid of panes |
| cts-settings-vc-030 | groups-frame-and-divider-controls | Load the Spacing panel | Two groups exist, titled "Frame Spacing" and "Pane Divider Spacing" respectively, each containing exactly one spacing control |
| cts-settings-vc-031 | binds-frame-spacing-to-settings | Change the top frame-spacing setting externally after loading | The frame-spacing control's displayed top value updates to match |
| cts-settings-vc-032 | closes-tab-loop-between-spacing-controls | Focus the frame-spacing control's last number field, press Tab | Focus moves to the divider-spacing control's first number field (and Tab from its last field returns focus to the frame-spacing control's first field) |
| cts-settings-vc-033 | binds-divider-spacing-to-settings | Change the between-columns gutter setting externally after loading | The divider-spacing control's displayed value updates to match |
| cts-settings-vc-034 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

