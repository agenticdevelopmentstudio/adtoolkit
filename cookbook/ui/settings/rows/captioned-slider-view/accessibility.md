
- **Role/trait**: Not observable beyond the platform's defaults — no
  custom accessibility role or element grouping is set in source. The
  slider and text elements each carry the platform's built-in
  accessibility role (slider, static text) automatically.
- **Label requirements**: The title label and the slider are laid out as
  sibling elements in the same row, but source sets no accessibility link
  (equivalent to a label/title-element association) on the slider linking
  it to the title text — confirmed by comparison with sibling row
  controls in this system, several of which do set that link on their
  control, but neither this component nor the plain slider row it's
  modeled on does so. Without that link, a screen reader announces the
  slider on its own when focus lands on it, with no route to the row's
  title text, unlike the sibling control-with-label rows.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself (see
  States); there is no state transition to announce.
- **Minimum tap target**: Not applicable — the component's interactive
  element is a continuous drag control (the slider) sized to the row's
  available width and the platform's own control metrics, not a small
  fixed-size tap target to check against a minimum (see Platform Notes
  for platform-specific minimum-control-size guidance).

