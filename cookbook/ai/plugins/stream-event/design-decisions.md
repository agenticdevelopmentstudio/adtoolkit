
**Decision**: `consume(_:)` and `finish()` are both non-throwing; a frame that cannot be decoded simply yields no event, with no distinct error signal.
**Rationale**: This keeps every conforming decoder simple — none of the five shipped decoders (`ClaudeSSEDecoder`, `OpenAIReplyDecoder`, `GeminiReplyDecoder`, `ChatReplyDecoder`, `PlainTextDecoder`) needs error-propagation plumbing — but it means a genuinely malformed, unrecoverable frame is indistinguishable from one that is merely incomplete and awaiting more bytes; both currently vanish silently. This is the same gap the behavior described under decode-failure-signal documents.
**Approved**: pending

**Decision**: `AIStreamEvent` declares three cases — `textDelta`, `toolUse`, `end` — even though no `AIStreamDecoder` shipped in this repository (`ClaudeSSEDecoder`, `OpenAIReplyDecoder`, `GeminiReplyDecoder`, `ChatReplyDecoder`, `PlainTextDecoder`) ever returns a `.toolUse` event.
**Rationale**: Every consumer's `switch` over `AIStreamEvent` (`LocalChatSession.swift`, `AIPluginChatBackend.swift`, `AIPluginLanguageModelProvider.swift`, `ChatBackendSession.swift`) already handles `.toolUse` exhaustively, so the case is part of the declared contract in preparation for a future tool-calling-capable decoder, not dead code — a source-fidelity note rather than a gap, since nothing here needs `.toolUse` to be produced today.
**Approved**: pending

**Decision**: `AIStreamDecoder` deliberately omits `Sendable`, unlike the sibling `AIPlugin` protocol, which requires it. (Apple platform implementation.)
**Rationale**: A decoder's whole purpose is to hold mutable per-response parsing state (buffered bytes, partial JSON); requiring `Sendable` would force every conformer to add locking for state that is, by design, never touched from more than one task. `AIPlugin` instances, by contrast, are commonly cached and reused across concurrent requests (see the sibling `AIPlugin` recipe's `concurrent-invocation-safety` requirement), so it needs `Sendable` where a decoder does not.
**Approved**: pending

**Decision**: `finish()` provides a default no-op implementation via a protocol extension rather than being a required method every conformer must implement. (Apple platform implementation.)
**Rationale**: A buffered whole-response decoder like `OpenAIReplyDecoder` needs an explicit `finish()` to emit its accumulated reply, but a decoder with no trailing state to flush (such as `LineDecoder` in `PluginTransportTests.swift`) has nothing useful to say when the stream closes; the default lets such a decoder omit the method entirely instead of writing a body that only returns `[]`.
**Approved**: pending

**Decision**: A permanently malformed frame is not observable by the host.
**Rationale**: There is no decode-error case or failure path, so a corrupt frame looks the same as an incomplete one; every current provider's wire format (server-sent-event lines, newline-delimited JSON, plain text) is line-oriented and resynchronizes on the next frame regardless of one bad line, so closing the gap takes a design decision on whether permanently malformed ever needs to be observable and, if so, an explicit decode-error case.
**Approved**: pending

