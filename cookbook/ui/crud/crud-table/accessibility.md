
- Renders a semantic `<table>` with a `<thead>`/`<tbody>`; header cells are `<th>`.
- The trailing per-row actions column header is empty visually but carries
  `aria-label="Row actions"` so it is named for assistive tech.
- Edit / Delete / New are real, focusable `<button>`s (the shared `Button`) with
  visible text labels and keyboard activation.
- The count line ("N rows" / "Loading…") gives sighted and AT users a sense
  of table size. It is plain text with no `aria-live` region, so an assistive
  technology user does not get an automatic announcement when it changes.
- **minimum-contrast-ratio**: The header, cell and muted caption text colors resolve from the active theme's `apt-*` text token roles against the hosting background at runtime. The component performs no contrast check of its own, so whether a theme's resolved pair meets 4.5:1 depends on that theme's values.

