
**Decision**: The container's fill color is the theme's `secondaryText` color at 0.08 alpha rather than a dedicated "indicator" color role.
**Rationale**: Per the source's own inline comment, this "matches the assistant bubble's fill, so the indicator reads as the message that is about to appear rather than a separate control." The exact shared role or value the assistant bubble itself uses is outside this file and is not verified here.
**Approved**: pending

**Decision**: Exactly one dot is fully opaque at a time, cycling in a fixed 0 → 1 → 2 order, rather than all three dots fading in and out together.
**Rationale**: Traceable to `tick()`'s `index == active` conditional. This produces the familiar left-to-right "chase" read as typing, rather than a synchronized pulse. On AppKit, the dots sit in a horizontal `NSStackView`, so their visual left-to-right order follows the layout direction and the chase direction would mirror automatically in a right-to-left layout; the source does not special-case this.
**Approved**: pending

**Decision**: The animation has no `stopAnimating()` counterpart to `startAnimating()`; the only thing that halts it is `removeFromSuperview()`.
**Rationale**: Not explained in source comments. This is consistent with how the component is used elsewhere in the chat feature — inserted while a message is sending and removed once it is not — so removal doubles as the stop signal in that usage. It does mean a caller that wants to keep the view in the hierarchy but pause the animation (e.g. hide it) has no API for that; see the "View hidden but not removed" and "Repeated calls to `startAnimating()`" edge cases.
**Approved**: pending

**Decision**: Reduce Motion and Increase Contrast are left unhandled in this file.
**Rationale**: Not explained in source comments; recorded here as known technical debt affecting behavioral correctness for users with either preference enabled — the component does not respond to Increase Contrast, and the rendered contrast is covered by **low-alpha-contrast** and its Design Decision.
**Approved**: pending

**Decision**: The container fill and dimmed dot state have no contrast floor against the host background.
**Rationale**: Both are fixed alpha multipliers over whatever background the host supplies and the component performs no contrast check; closing the gap takes a contrast judgment of the rendered indicator against each host background in the running UI, or a contrast floor enforced by the component.
**Approved**: pending

