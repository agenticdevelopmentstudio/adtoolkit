
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

