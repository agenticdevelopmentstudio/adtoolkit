
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because the overlay owns only the conversation
(the poll, the narrowed session and the Return rule) and leaves backdrop,
fade and dismissal to the dismissible overlay and rows to the transcript
view. `keyboard-navigable` passes because the composer takes the focus on
presentation and Escape closes from anywhere. `screen-reader-support` is
partial because the source sets an accessibility identifier but no label and
posts no notification when the overlay appears or disappears.

`unit-test-coverage` is `partial`. `Chat/ConversationFocusTests.swift` drives
the overlay through the Conversations feed: `testDoubleClickingARowOpensAnOverlayHoldingThatSessionAlone`
(single-session-read), `testTheOverlayCoversTheWholeFeed` and
`testTheOverlayIsDrawnBeforeItStartsToFadeIn` (fills-host and the seeded
first frame), `testALineTypedBeforeTheFirstReadKeepsTheTranscriptItWasSeededWith`
(seed-survives-early-send), `testTheOverlayShowsAMessageWhole`
(line-limit), `testAnOverlayWithNowhereToWriteKeepsItsComposerOff` and
`testAnOverlayTheHostCanWriteToOffersItsComposer` (composer-follows-sendability),
`testTheOverlayHasNoRowSelection` and `testTheOverlayOffersNoJumpOnItsRows`
(no-row-actions), `testTheOverlayTakesTheKeysForItsComposer` and
`testAnOverlayWithNowhereToWriteLeavesTheKeysAlone` (focus-composer-on-present),
and `testEscapeDismissesTheOverlay`, `testReturnDismissesTheOverlay`,
`testAnOrdinaryKeyLeavesTheOverlayUp`, `testAPressThatNoControlTookDismissesTheOverlay`
and `testClickingABubbleInsideTheOverlayDoesNotDismissIt` (dismissal-gestures
with the composer unfocused). No test covers periodic-refresh,
on-demand-refresh, stop-reading-before-fade, return-belongs-to-composer,
escape-always-dismisses with the composer focused, terminal-bubble-style,
composer-prompt, transparent-transcript or the accessibility identifier.

