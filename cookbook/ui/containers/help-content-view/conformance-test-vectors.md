
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-content-view-001 | fixed-help-heading | Construct the component | A label with text exactly "Help" exists, pinned 20pt from the view's top and leading edges, outside the scroll view's document |
| help-content-view-002 | independently-scrolling-content | Set help content whose combined height exceeds the view's frame, then scroll the document | The heading label's frame is unchanged while the visible topic content scrolls |
| help-content-view-003 | topic-groups | Set help content with topics [(title: "A", body: "a"), (title: "B", body: "b")] | The panel contains exactly 2 groups in order, titled "A" then "B", each with one explanation row whose text matches the topic's `body` |
| help-content-view-004 | empty-state | Set help content to no content | The panel contains exactly 1 group titled "No Help Yet" with one explanation row reading the fixed empty-state sentence |
| help-content-view-005 | empty-state | Set help content to content with an empty topics list | Same result as help-content-view-004 |
| help-content-view-006 | wholesale-replacement | Set help content to topic set A, then set it again to topic set B | After the second call, none of topic set A's groups/explanation rows remain in the panel; only topic set B's are present |
| help-content-view-007 | scroll-reset | Set help content to tall content, scroll to the bottom, then set help content again to new content | The scroll view's visible origin is back at the top immediately after the second call returns |
| help-content-view-008 | theme-application, window-background | Construct the component while Theme A is active | Background color equals Theme A's `windowBackgroundColor` (not a distinct or hardcoded color); heading font equals Theme A's `.heading` font; heading text color equals Theme A's `primaryTextColor` |
| help-content-view-009 | theme-application | With the component constructed under Theme A, switch the active theme to Theme B | All three properties from help-content-view-008 update to Theme B's values without re-constructing the view |
| help-content-view-010 | coder-init-unavailable | Attempt to construct the view from a serialized or archived representation | Construction is refused as a programmer error and terminates; no instance is produced. Verified by inspection only, since the refusal cannot be caught. |
| help-content-view-011 | minimum-contrast-ratio | Construct the component under a theme whose primary text color is close to its window background color | The heading label's color equals the theme's primary text color exactly; no contrast adjustment is applied. |
| help-content-view-012 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

`coder-init-unavailable` is vector 010; because the refusal terminates the process, it is verified by inspection rather than by an automated test (see Platform Notes).

