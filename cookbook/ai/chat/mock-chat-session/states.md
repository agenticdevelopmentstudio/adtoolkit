
Not applicable — this is a headless, in-memory test double for a chat engine, not a visual component. Its runtime lifecycle is expressed through the `ChatEvent.stateChanged(ChatSessionState)` events it emits (`.ready`, `.responding`; it never emits `.connecting`, `.failed`, or `.closed`), which are captured under Behavioral Requirements above, not in a visual-state table.

