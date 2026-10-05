
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-panel-split-view-controller-001 | exposes-descriptor | Construct with an explicit descriptor whose title is `"Theme"` | The descriptor's title is `"Theme"` |
| settings-panel-split-view-controller-002 | defaults-descriptor-when-omitted | Construct with no descriptor | The descriptor is a default descriptor whose title is `""` |
| settings-panel-split-view-controller-003 | titles-sidebar-from-descriptor | Construct with a descriptor whose title is `"Theme"` | The sidebar title is `"Theme"` |
| settings-panel-split-view-controller-005 | acts-as-hostable-panel | Construct an instance and add it as a panel of a separate, outer settings split | The outer split accepts it without a compile or runtime error; the instance appears in the outer split's panel list |
| settings-panel-split-view-controller-006 | returns-nil-help-content-by-default | Read the help content on a plain (non-subclassed) instance | Returns none |
| settings-panel-split-view-controller-007 | falls-back-help-content-through-inner-selection | Select an inner panel whose effective help content is non-empty | Effective help content on this instance returns that same value |
| settings-panel-split-view-controller-008 | falls-back-help-content-through-inner-selection | No inner panel selected, and a subclass overrides help content to a non-empty value | Effective help content returns that overridden help-content value |
| settings-panel-split-view-controller-009 | falls-back-help-content-through-inner-selection | An inner panel is selected, its effective help content is empty, and a subclass overrides this panel's own help content to a non-empty value | Effective help content falls through the inner selection's empty value and returns the subclass's overridden help content |
| settings-panel-split-view-controller-010 | surfaces-empty-help-when-chain-exhausted | No inner panel is selected (or the inner selection's effective help content is empty), and no subclass overrides help content | Effective help content evaluates to none |
| settings-panel-split-view-controller-011 | reports-no-additional-search-keywords | Read search keywords on a plain (non-subclassed) instance | Returns an empty list |
| settings-panel-split-view-controller-012 | narrows-detail-minimum-thickness | Read the detail-pane minimum-thickness floor | Returns `200` |
| settings-panel-split-view-controller-013 | fixes-content-sized-sidebar | Read the content-sized-sidebar flag | Returns true |
| settings-panel-split-view-controller-014 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

