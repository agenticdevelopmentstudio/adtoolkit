
- **hardcoded-role-rejection-messages**: the message `sendRequest` uses to reject a call with an unsupported `role` names the offending role value and is a hardcoded English string literal with no localization key. It is visible to the extension author whose call triggered it, not to the app's own end-user UI.
- **hardcoded-teardown-messages**: the torn-down messages `selectChatModels`, `sendRequest`, and `onDidChangeChatModels` each produce (built by a shared teardown helper every `vscode` member adaptor uses, not by this component directly) are likewise hardcoded English, in the fixed shape `"<path> is unavailable: this extension's host has been torn down."`.
- **hardcoded-cursor-rejection-messages**: the message rejecting a displaced `next()` waiter (**one-outstanding-next-per-cursor**) and the message a bridging or cancellation failure surfaces on a cursor are both hardcoded English error descriptions with no localization mechanism.
- **hardcoded-log-strings**: every error-log call this component makes (a dropped chat-model object, a displaced waiter, a bridging failure, a tool-call JSON parse failure) is a hardcoded English interpolated string, also unlocalized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `vscode.lm.selectChatModels is unavailable: this extension's host has been torn down.` | Shared teardown helper, produced when `selectChatModels` reaches a torn-down component. |
| (none — literal only) | `vscode.lm.sendRequest` (chat model object) `is unavailable: this extension's host has been torn down.` | Shared teardown helper, produced when `sendRequest` reaches a torn-down component. |
| (none — literal only) | `vscode.lm.onDidChangeChatModels is unavailable: this extension's host has been torn down.` | Shared teardown helper, produced when `onDidChangeChatModels` reaches a torn-down component. |
| (none — literal only) | A message naming the unsupported `role` value | `refuseUnsupportedRole`, raised when a message's `role` is not `1` or `2`. |
| (none — literal only) | A message naming the one-outstanding-`next()` constraint | The cursor executor, raised on the earlier of two overlapping `next()` calls. |

