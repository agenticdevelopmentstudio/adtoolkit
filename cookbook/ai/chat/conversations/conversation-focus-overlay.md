---
id: 08448e7e-b673-49b3-97d4-d83136d108d6
title: "Conversation Focus Overlay"
domain: adtoolkit://cookbook/ai/chat/conversations/conversation-focus-overlay
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Lays one conversation, lifted out of a merged feed, over the blurred feed as a chat transcript that keeps itself current and can be answered in place."
platforms:
  - swift
  - macos
tags:
  - chat
  - overlay
  - conversations
depends-on:
  - adtoolkit://cookbook/ui/containers/dismissible-overlay-view
related:
  - adtoolkit://cookbook/ai/chat/chat-window/chat-view
  - adtoolkit://cookbook/ai/chat/mock-chat-session
references: []
approved-by: ""
approved-date: ""
---

# Conversation Focus Overlay

## Overview

A merged feed of several sessions is readable and still hard to follow: the
reply to the line a reader is on is several rows down, under other
projects' traffic. This overlay pulls one session to the front, with the
same rows and bubbles and nothing else on the timeline, and the blurred feed
behind it says that this is a closer look at the feed rather than a
different window. It is the chat transcript view placed over the blurred
ground the dismissible overlay supplies, so a fix to bubbles, theming or
scroll anchoring lands in both the overlay and the feed it covers. What it
adds to the dismissible overlay is only the conversation: a poll that keeps
one session current, a composer that writes back to that session when the
host can, and one change to the dismissal keys so that Return belongs to the
composer while the composer has the keys.

## Behavioral Requirements

- **single-session-read**: Component MUST read its transcript only through
  the caller-supplied loader, which is already narrowed to one session, and
  MUST show only the rows that loader returns.
- **seeded-first-frame**: Component MUST show the caller-supplied seed rows
  from its first frame, before any read has completed, so it fades in
  holding the conversation rather than filling in afterwards.
- **seed-survives-early-send**: Component MUST keep the seed rows in the
  transcript when a line is sent before the first read lands, rather than
  publishing an empty transcript around the pending line.
- **periodic-refresh**: Component MUST re-read its conversation at the
  caller-supplied refresh interval for as long as it is presented.
- **on-demand-refresh**: Component MUST re-read its conversation
  immediately when its refresh operation is called, without waiting for the
  next interval.
- **stop-reading-before-fade**: Component MUST stop reading its conversation
  when dismissal begins, before the fade-out animation starts, and MUST also
  stop when the component is discarded.
- **fills-host**: Component MUST cover its whole host and MUST pin its
  transcript view to all four edges of itself, composer included.
- **transparent-transcript**: The transcript view MUST draw no background of
  its own, so the blurred feed shows through it.
- **terminal-bubble-style**: Component MUST draw its rows with the same
  terminal bubble shape the feed uses, not the chat window's speech bubble.
- **line-limit**: Component MUST show at most the caller-supplied number of
  lines of a message before offering the rest, and MUST show a message whole
  when the limit is absent.
- **composer-follows-sendability**: Component MUST enable its composer if and
  only if a send handler was supplied, and MUST show the composer greyed out,
  not removed, when none was.
- **composer-prompt**: Component MUST label its composer with the `>` prompt.
- **no-row-actions**: Component MUST NOT offer a row action of any kind: no
  open action, no jump-to-source action, and no row selection.
- **focus-composer-on-present**: Presenting the component MUST give the
  keyboard focus to the composer when a send handler was supplied, and MUST
  leave keyboard focus where it was when none was.
- **return-belongs-to-composer**: While the composer has the keyboard focus,
  the component MUST report Return and keypad Enter as unhandled by
  dismissal, so they reach the composer.
- **escape-always-dismisses**: Escape MUST dismiss the component whether or
  not the composer has the keyboard focus.
- **dismissal-gestures**: Component MUST dismiss itself on an unclaimed press
  and, when the composer does not have the focus, on Return, keypad Enter
  and Escape, and MUST NOT dismiss on any other key or on a press a bubble
  claimed.
- **stable-accessibility-id**: Component MUST expose the accessibility
  identifier `conversation-focus.overlay`.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None; the overlay is edge to edge over the host.
- **Padding**: None of its own; the transcript view is pinned flush to all
  four edges and supplies its own row insets.
- **Font**: Inherited from the transcript view's rows; the composer shows the
  `>` prompt.
- **Background**: The dismissible overlay's blurred backdrop (the platform
  hud-style material); the transcript draws no background over it.
- **Foreground/Text**: Inherited from the transcript view's terminal bubble
  style.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: None; it always fills its host.

## States

| State | Appearance change |
|-------|------------------|
| Default | Blurred feed behind a transcript of one session, composer enabled when a send handler exists |
| Seeded, not yet read | The seed rows are drawn; the first read replaces or extends them |
| Read-only session | Composer greyed out and not focused; Return and Escape dismiss |
| Writable session, composer focused | Return sends the line; Escape dismisses |
| Dismissing | Reading has stopped; the overlay fades out as in the dismissible overlay |
| Pressed | Not applicable beyond the dismissible overlay's unclaimed-press rule |
| Disabled | Composer only, when no send handler was supplied |
| Focused | The composer holds the keys on presentation when it is enabled |
| Loading | Not shown; the seed stands in until the first read |

## Accessibility

- **Role/trait**: The overlay carries the identifier `conversation-focus.overlay`;
  its transcript and composer carry the transcript view's own roles.
- **Label requirements**: Inherited from the transcript view; the overlay adds
  none, and, as in the dismissible overlay, nothing announces how to dismiss it.
- **Announce state changes**: Not implemented; no notification is posted on
  appearing or disappearing.
- **keyboard-reachability**: A reader MUST be able to answer and to close the
  overlay with the keyboard alone: the composer takes the focus on
  presentation, Return sends, and Escape closes.
- **Minimum tap target**: Not applicable; the overlay adds no controls of its
  own.
- **Minimum contrast ratio**: Inherited from the transcript view.

## Conformance Test Vectors

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

## Edge Cases

- **Null/empty input**: An empty seed shows an empty transcript until the
  first read lands; an absent send handler greys the composer (per
  `composer-follows-sendability`); an absent line limit shows messages whole
  (per `line-limit`).
- **Boundary values**: A line limit of one is the smallest sensible cap; a
  refresh interval is the caller's to choose and is not clamped here.
- **Concurrent access**: Not applicable beyond the poll: reads are driven by
  the session, and the overlay stays on the UI thread.
- **Error states (dependency/network failure)**: A failed read leaves the
  transcript as it was; a line that cannot be delivered is marked failed by
  the transcript, not by this component.
- **Offline/disconnected state**: Reads fail quietly and the last transcript
  stays on screen.
- **Return while composing** (MUST): Return sends the line instead of closing
  the overlay (per `return-belongs-to-composer`), because an overlay that
  vanished would throw the typed line away; Escape remains the way out.
- **Dismissal during a poll**: Reading stops before the fade (per
  `stop-reading-before-fade`) so no poll lands in the fade and rebuilds a
  transcript nobody will see.
- **Feed pushes**: The feed behind is pushed to when its source changes; the
  host forwards that push through the refresh operation so the overlay is not
  up to one interval behind.

## Configuration

Construction options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `refreshInterval` | duration | required | How often this conversation is re-read; the feed's own cadence |
| `load` | loader | required | Reads this conversation, already narrowed to its session |
| `seed` | list of messages | empty | Rows the feed already holds for this session |
| `lineLimit` | integer or none | required | Lines shown per message before the rest is offered; none shows whole |
| `send` | sender or none | none | Types a line into the session; none disables the composer |

The component also exposes a refresh operation, and it inherits the
dismissible overlay's presentation and dismissal operations.

## Deep Linking

Not applicable: a host constructs and presents the overlay directly; it has
no route of its own.

## Localization

The composer prompt `>` is a symbol, not translatable text. All other text
belongs to the transcript view and its rows.

## Accessibility Options

- **Reduce Motion**: Inherited: the only animation is the dismissible
  overlay's opacity fade.
- **Increase Contrast**: Inherited from the transcript view and the platform
  material.
- **Differentiate Without Color**: Not applicable; the overlay conveys no
  state by color of its own.

## Feature Flags

Not applicable: the overlay presents unconditionally when asked.

## Analytics

Not applicable: no tracking call exists in the source.

## Privacy

- **Data collected**: None of its own; it shows whatever the supplied loader
  returns and forwards typed lines to the supplied sender.
- **Storage**: None; the transcript lives in memory for the overlay's
  lifetime.
- **Transmission**: Only through the caller's loader and sender.
- **Retention**: Discarded with the overlay.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **AppKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/Features/ConversationsWindow/ConversationFocusOverlay.swift`
  as a `public final` subclass of `DismissibleOverlayView` that holds a
  `ChatView`, a `FeedChatSession` and an `AIChatViewModel`. The initializer
  takes `refreshInterval: Duration`, `load: FeedChatSession.Loader`,
  `seed: [ChatMessage]`, `lineLimit: Int?` and `send: FeedChatSession.Sender?`,
  and calls the superclass with the `.hudWindow` material. The seed goes to
  both the session and the view model: the view model's copy is what is
  drawn, the session's is what it publishes around. It sets
  `chatView.drawsBackground = false`, `isComposerEnabled = session.canSend`,
  `composerPrompt = ">"`, `bubbleLineLimit = lineLimit`,
  `bubbleStyle = .terminal` and `rowActions = .init()`, then pins the chat
  view to all four anchors. `present(in:)` calls super and then
  `chatView.focusInput()` when `session.canSend`. `performKeyEquivalent(with:)`
  returns `false` for key codes 36 and 76 when `chatView.isComposerFocused`,
  otherwise defers to super. `refresh()` calls `session.refresh()`;
  `willDismiss()` and `deinit` call `session.close()`.
- **confines-to-ui-thread**: On Apple platforms the type is `@MainActor`-isolated, so the compiler enforces the rule.
- **SwiftUI**: Layer a transcript view over a blurred material in a `ZStack`
  and attach the poll to the view's lifetime with `.task`, cancelling it on
  disappearance.
- **WinUI 3**: Use an `AcrylicBrush` backdrop under a transcript control;
  mark Return handled on the composer so it does not reach the dismiss
  accelerator.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/Features/ConversationsWindow/ConversationFocusOverlay.swift` |

## Design Decisions

**Decision**: The overlay subclasses the dismissible overlay and the chat
view rather than drawing its own transcript.
**Rationale**: The source's doc comment says the overlay is "the same
transcript UI as the thing it covers: a fix to bubbles, theming or scroll
anchoring lands in both at once."
**Approved**: pending

**Decision**: Return is the composer's while the composer has the keys; Escape
still closes from anywhere.
**Rationale**: The source's doc comment says an overlay that vanished on Return
"would throw the line away," and that Escape leaves "always a way out."
**Approved**: pending

**Decision**: The overlay offers no row actions.
**Rationale**: The source's comment says an open action would open the
conversation the reader is already in, and the app icon answers a question a
merged feed asks but this view has already answered.
**Approved**: pending

**Decision**: Reading stops in the pre-dismissal hook rather than only when the
overlay is discarded.
**Rationale**: The source's comment says the fade is "a fifth of a second in
which a poll would otherwise land and rebuild a transcript nobody is going
to see."
**Approved**: pending

## Compliance

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

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial spec for the conversation focus overlay, split out of the mock chat session spec where it was misattributed. |
