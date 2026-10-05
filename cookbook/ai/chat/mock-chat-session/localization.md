
- **hardcoded-default-reply-string**: The default `reply` parameter value, `"This is a mock reply."`, is a hardcoded English literal with no localization mechanism wrapping it. A caller that does not override `reply` MUST see exactly that literal English text rendered in the transcript by whatever view consumes it. MUST (stated as an observed fact, not a proposal).
- **stop-reason-not-user-facing**: The literal stop reason `"end_turn"` is an internal `ChatEvent` payload value passed between the session and its view model, not text rendered to a reader, so it carries no localization concern.

