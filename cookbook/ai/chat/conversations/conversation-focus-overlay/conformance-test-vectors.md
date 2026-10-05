
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-focus-001 | single-session-read | Open the overlay on one session of a feed holding two | The loader is asked only for that session and the rows shown are that session's alone |
| conversation-focus-002 | seeded-first-frame | Open the overlay with seed rows and inspect it before any read completes | The seed rows are already shown |
| conversation-focus-003 | seed-survives-early-send | Send a line before the first read lands | The transcript still holds the seed rows plus the pending line |
| conversation-focus-004 | periodic-refresh | Keep the overlay presented across several refresh intervals | The loader is called once per interval |
| conversation-focus-005 | on-demand-refresh | Call the refresh operation between intervals | The loader is called at once |
| conversation-focus-006 | stop-reading-before-fade | Dismiss the overlay, then wait past an interval | No further read happens, including while the fade runs, and none happens after the overlay is discarded |
| conversation-focus-007 | fills-host | Present the overlay and inspect its frame and its transcript's frame before the fade starts | The overlay's frame equals the host's bounds and the transcript's frame equals the overlay's bounds |
| conversation-focus-008 | transparent-transcript | Inspect the transcript view | It draws no background |
| conversation-focus-009 | terminal-bubble-style | Inspect the style of the rows | They use the terminal bubble style |
| conversation-focus-010 | line-limit | Open one overlay with a limit and one with none, each over a long message | The first truncates at the limit; the second shows the message whole |
| conversation-focus-011 | composer-follows-sendability | Open one overlay with a send handler and one without | The first composer is enabled; the second is present but disabled |
| conversation-focus-012 | composer-prompt | Inspect the composer's prompt | It is `>` |
| conversation-focus-013 | no-row-actions | Inspect the rows of an open overlay | Rows are not selectable and their app icons carry no jump action |
| conversation-focus-014 | focus-composer-on-present | Present one overlay with a send handler and one without | The first gives the focus to the composer; the second leaves the focus where it was |
| conversation-focus-015 | return-belongs-to-composer | Focus the composer, then send a Return key event to the overlay | The event is reported as unhandled and the overlay stays up |
| conversation-focus-016 | escape-always-dismisses | Focus the composer, then send an Escape key event | The event is handled and the overlay dismisses |
| conversation-focus-017 | dismissal-gestures | On overlays whose composer is not focused, send Escape, Return, a down-arrow and an unclaimed press, and separately press a bubble | Escape, Return and the unclaimed press dismiss; the down-arrow does not; the bubble press does not |
| conversation-focus-018 | stable-accessibility-id | Read the overlay's accessibility identifier | It is `conversation-focus.overlay` |
| conversation-focus-019 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

