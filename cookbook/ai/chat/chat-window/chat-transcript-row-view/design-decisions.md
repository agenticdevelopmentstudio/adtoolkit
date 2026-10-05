
**Decision**: The app icon is sized 28×28pt — short of the 44pt the Sessions window gives the identical control, but larger than the 24pt symbol it replaces.
**Rationale**: In the transcript, the icon heads one line of a timeline whose subject is what was said, not the row's whole identity the way it is in the Sessions window; 28pt keeps it recognizable as artwork (a picture to be recognised, not a glyph to be read) without claiming the row.
**Approved**: pending**

**Decision**: The app icon's target, tooltip, and accessibility label are set only when `actions.onJump` is non-nil; an unwired icon renders with no target.
**Rationale**: The icon promises a link under the pointer wherever it is hovered; a promise kept by nothing is worse than no promise, so the promise is only made where it is actually kept.
**Approved**: pending**

**Decision**: Hover fill and the pointing-hand cursor are gated on `actions.onOpen`, not on `actions.onSelect` or `actions.onJump`.
**Rationale**: They promise that pressing the row itself means something — specifically, that a press opens the conversation — so they track the row's own primary action rather than any closure being present.
**Approved**: pending**

**Decision**: Selection is drawn as a 2pt border rather than a background fill.
**Rationale**: The hover fill already means "the mouse is here"; a second fill would leave a reader unable to tell a hovered row from a selected one, and a border leaves the bubble's own color — which encodes who is talking — untouched.
**Approved**: pending**

**Decision**: Opening a row requires a double click; a single click is reserved for selection and for starting a text-selection drag inside the bubble.
**Rationale**: A single click is worth more where it already is — selecting text to copy it — and opening a conversation is deliberate enough to be worth two clicks instead of contesting that gesture.
**Approved**: pending**

**Decision**: The row is laid out with hand-written `NSLayoutConstraint`s mirrored per role, rather than nested stack views, with the header line as the one exception (it stays a stack).
**Rationale**: The row mirrors about its own centre line, and "the same layout, flipped" is one set of anchors chosen per side, where stack views would need two separate hierarchies; the header line is the shared control used identically in the Sessions window and Conversations shelf, so it keeps its own internal arrangement regardless of which margin the whole line is pinned to.
**Approved**: pending**

**Decision**: `showsInlineTimestamp: false` is passed to the embedded bubble, and the row draws its own timestamp label on its own line instead.
**Rationale**: The row's own timestamp is anchored to the same edge as the header's breadcrumb trail — the speaker's column — so it has to be a label this row positions itself; a timestamp the bubble drew inline would be part of the bubble's own shape and could not be pinned independently to that column (see `adtoolkit://cookbook/ai/chat/chat-window/chat-bubble-view`).
**Approved**: pending**

**Decision**: The app icon's 28x28pt hit area is not padded to 44x44pt.
**Rationale**: The icon is a real, always-clickable-when-wired control, but the shared session-header component sizes the button to its artwork and there is no existing hit-area padding technique to reuse; closing the gap takes the accessibility/design owner either accepting 28pt for this pointer-driven surface or padding the tappable area to 44x44pt independent of the artwork.
**Approved**: pending

