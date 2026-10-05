
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-window-001 | identifies-window-as-settings | Construct the window | Its window id is `"settings"`. |
| settings-window-002 | titles-window-settings | Construct the window | Its window title is `"Settings"`. |
| settings-window-003 | hides-window-title-visibility | Show the window | The window's title text is hidden. |
| settings-window-004 | extends-content-under-title-bar | Inspect the window after construction | It remains titled, closable, miniaturizable, and resizable, with its content extended under the title bar. |
| settings-window-005 | suppresses-sidebar-title | Construct the window | The hosted split view has no sidebar title. |
| settings-window-006 | shows-sidebar-search | Construct the window | The hosted split view shows a sidebar search field. |
| settings-window-007 | sorts-panels-alphabetically | Construct the window | The hosted split view sorts panels alphabetically by title. |
| settings-window-008 | exposes-setting-panels | Assign the panel list to `[panelB, panelA]` | The hosted split view's panel list reflects the assignment. |
| settings-window-009 | activates-app-on-show-by-default | Construct the window with no override | Activate-on-show is enabled. |
| settings-window-010 | allows-subclass-to-disable-activation | Override activate-on-show to disabled | The override value is honored (activate-on-show is disabled). |
| settings-window-011 | skips-activation-when-disabled | Activate-on-show is disabled; show the window | The app is not activated, and only the base show behavior runs, with no further window operation of its own. |
| settings-window-012 | shows-quietly-under-quiet-presentation | Activate-on-show is enabled; quiet presentation is enabled; show the window | The window is made key without activating the app. |
| settings-window-013 | activates-and-keys-window-normally | Activate-on-show is enabled; quiet presentation is disabled; show the window | The app is activated, then the window is made key and frontmost, in that order. |
| settings-window-014 | attaches-help-drawer-presenter | Trigger window configuration (first show) | The hosted split view's help presenter is a help panel presenter built with that window. |
| settings-window-015 | installs-unified-toolbar-chrome | Trigger window configuration | The window has a unified, icon-only header bar the user cannot customize, a transparent title bar, and no title-bar separator. |
| settings-window-016 | fixes-toolbar-item-order | Read the header bar's default and allowed item lists | Both equal: the sidebar tracking separator, the navigation control, the panel-title item, a flexible space, and the help control, in that order. |
| settings-window-017 | hides-inline-help-button | Trigger window configuration | The hosted split view's inline help control is hidden. |
| settings-window-018 | builds-back-forward-as-one-control | Inspect the navigation control | One segmented control, momentary tracking, separated style, 2 segments, accessibility label "Back and forward". |
| settings-window-019 | routes-segment-selection-to-navigation | Choose the back segment, then the forward segment, then simulate no selection | Navigate back is triggered once, navigate forward is triggered once, no call on the third case. |
| settings-window-020 | syncs-navigation-control-enablement | Moving back is not possible, moving forward is possible; navigation state changes | Back segment disabled, forward segment enabled. |
| settings-window-021 | shows-current-panel-title | Current panel title is `"General"`; navigation state changes | Panel-title item's text is `"General"`. |
| settings-window-022 | renders-panel-title-as-single-line-heading | Inspect the panel-title item | Non-editable, truncates overflow at the end, hugs content horizontally, primary-text color role, heading text role. |
| settings-window-023 | shows-outline-glyph-when-drawer-closed | Help panel is not visible; help visibility changes | Help control's icon is the outline question-mark icon. |
| settings-window-024 | shows-filled-glyph-when-drawer-open | Help panel is visible; help visibility changes | Help control's icon is the filled question-mark icon. |
| settings-window-025 | tints-help-button-by-drawer-state | Toggle help visibility off then on | Tint is secondary-text color then accent color. |
| settings-window-026 | swaps-help-tooltip-by-drawer-state | Toggle help visibility off then on | Tooltip reads "Show Help" then "Hide Help". |
| settings-window-027 | keeps-help-accessibility-name-stable | Toggle help visibility through several open/close cycles | The help icon's accessibility description is "Help" after every cycle. |
| settings-window-028 | updates-help-glyph-on-visibility-change | Help visibility changes after the panel opens | Help control's icon/tint/tooltip refresh to the open state. |
| settings-window-029 | updates-help-glyph-on-navigation-change | Navigation state changes while the help panel is open | Help control's icon/tint/tooltip reflect the open state. |
| settings-window-030 | wires-help-only-for-inserted-item | The help control is built as a non-live copy, not the one being inserted | The help control reference, its theme tracking, and its help-anchor view are left unset. |
| settings-window-031 | anchors-help-presenter-to-button | The help control is actually inserted | The help presenter's help-anchor view equals the returned control. |
| settings-window-032 | tracks-theme-live-on-help-button | Change the resolved theme palette after the help control is inserted | Help control icon/tint refresh without any other event firing. |
| settings-window-033 | toggles-help-on-click | Activate the inserted help control | The help panel's visibility toggles. |
| settings-window-034 | builds-tracking-separator-from-splitview | The hosted split view exists; request the sidebar tracking separator | Returns a separator item bound to that split view's first divider. |
| settings-window-035 | builds-tracking-separator-from-splitview | The hosted split view does not exist; request the sidebar tracking separator | Returns nothing. |
| settings-window-036 | assigns-high-visibility-to-primary-items | Inspect the navigation, panel-title, and help items | Each has high visibility priority. |
| settings-window-037 | returns-nil-for-unknown-toolbar-identifier | Request an item for an identifier outside the fixed list | Returns nothing. |
| settings-window-038 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

