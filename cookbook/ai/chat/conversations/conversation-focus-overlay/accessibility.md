
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

