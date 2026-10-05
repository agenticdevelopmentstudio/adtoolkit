
- **day-text-rendered**: The component MUST render, as the label's text, the day spelled out in full — full weekday name, full month name, unpadded day number, four-digit year — using the same day-formatting pattern applied elsewhere to message-timestamp day banners, e.g. "Wednesday, June 3 2026" for June 3, 2026 (see Platform Notes for the concrete formatter).
- **day-normalized-to-start-of-day**: The component MUST normalize the `day` value it is given to the start of that day, using the caller-supplied `calendar` (default the current calendar), before formatting or exposing it (see Platform Notes for the concrete call).
- **label-centered**: The component MUST center the date label horizontally within the view, so the label's horizontal center coincides with the view's horizontal center regardless of the view's width (see Platform Notes for the concrete constraint).
- **rules-flank-label**: The component MUST render one horizontal rule to each side of the label, with each rule's inner edge separated from the label by 10pt, so the rules occupy all remaining horizontal space between the label and the view's edges.
- **rules-equal-width**: The component MUST constrain the two rules to equal width to each other, so the label stays on the view's horizontal center line regardless of how wide the formatted date string is.
- **vertical-insets**: The component MUST reserve 16pt of space between the view's top edge and the label's top edge, and 8pt of space between the label's bottom edge and the view's bottom edge.
- **rule-thickness**: Each rule MUST be exactly 1pt tall and vertically centered on the label's own center line.
- **static-text-role**: The component MUST expose an accessibility role equivalent to static text on itself.
- **label-accessibility-label**: The component MUST set the label's accessibility label to the label's own rendered string value.
- **label-accessibility-identifier**: The component MUST set the label's accessibility identifier to `chat-day-banner`.
- **theme-responsive-styling**: The component MUST update the label's font, the label's text color, and both rules' colors whenever the active theme's palette changes, without being re-created.
- **day-and-title-exposed**: The component MUST expose the normalized day and the label's current rendered string as read-only public properties (`day` and `title` respectively).
- **coder-init-unavailable**: The component MUST NOT support construction through platform-archival deserialization (e.g. storyboard/XIB unarchiving); attempting that construction path MUST be a compile-time error, and MUST terminate the process if reached at runtime regardless (see Platform Notes for the concrete mechanism).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

