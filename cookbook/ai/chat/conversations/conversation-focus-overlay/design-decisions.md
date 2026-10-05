
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

