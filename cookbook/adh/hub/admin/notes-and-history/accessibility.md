
- **Role/trait**: No explicit accessibility role is applied anywhere in
  the design. Each subject area is a plain container headed by a heading
  landmark at heading level 4 ("Admin notes", "History"), so
  assistive-technology heading navigation exposes both section titles even
  though the containers themselves carry no accessible name of their own.
- **Label requirements**: Not applicable in the form-control sense: the
  component renders no input, button, or other labelable control. The only
  labels present are the two heading-level-4 section headings, which are
  plain text requiring no separate accessible-name wiring.
- **Announce state changes (e.g., loading, disabled)**: Not implemented.
  The loading-to-populated/empty transition is rendered as a plain text
  swap with no live-region announcement, so a screen-reader user is not
  proactively notified when a section's content resolves (WCAG 4.1.3
  Status Messages).
- **Minimum tap target**: Not applicable: the component renders no
  interactive element anywhere in its design (no button, link, or input),
  so there is no tap target to size.

