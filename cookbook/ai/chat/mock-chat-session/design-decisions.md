
**Decision**: An interrupted turn still yields `.responseFinished(stopReason: "end_turn")` and `.stateChanged(.ready)` — there is no distinct "interrupted" stop reason or session state.
**Rationale**: `MockChatSession` models only the visible effect of an interruption (fewer or zero `.responseDelta` events reaching the transcript); it does not model a `ChatSession` conformer that reports interruption as a distinct outcome. Any UI or test that depends on distinguishing a cleanly finished turn from an interrupted one cannot do so from this component's events alone.
**Approved**: pending

**Decision**: On the AppKit/UIKit implementation, `MockChatSession` is declared `@unchecked Sendable`, but only `continuation` is consistently accessed under its `lock`; `liveTurn` is not.
**Rationale**: This is the same gap as the behavior described under **live-turn-synchronization**, not a considered design choice — it is recorded here because `@unchecked Sendable` is exactly the kind of "trust me, it's synchronized elsewhere" declaration that Source Fidelity requires calling out rather than smoothing over, and because a port that copies the Swift structure literally (rather than the fixes proposed in Platform Notes) would carry the same race into its target platform.
**Approved**: pending

**Decision**: On the AppKit/UIKit implementation, `chunk(_:size:)` splits on `Character` count, not byte or UTF-16 count.
**Rationale**: This keeps chunk boundaries safely on grapheme cluster boundaries for any input, including multi-scalar characters and emoji, at essentially no extra code — Swift's `String.Index`-based `offsetBy:` is `Character`-aware by default. A port on a platform whose native string indexing is UTF-16-code-unit-based (JavaScript, C#) needs an explicit code-point- or text-element-aware split to keep the same guarantee; see Platform Notes.
**Approved**: pending

**Decision**: `send(_:)` performs no trimming or emptiness guard on its `text` argument, unlike the sibling `FeedChatSession.send(_:)`, which trims and rejects an empty trimmed string.
**Rationale**: `MockChatSession` is a scripted double whose reply never depends on the sent text (see **reply-independent-of-input**), so an empty or whitespace-only send has no failure mode to guard against here the way it does for `FeedChatSession`, which writes the text into a real destination and must not write nothing. The two types intentionally diverge on this point rather than sharing one send-validation rule.
**Approved**: pending

