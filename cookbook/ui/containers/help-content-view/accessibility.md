
- **Role/trait**: Not customized beyond the platform's defaults — no
  explicit accessibility role, trait, or heading designation appears
  anywhere in this component's source. The heading label is a plain text
  label, which the platform exposes to assistive technology as static text
  by default; it is never given a heading-level accessibility designation,
  so the platform's default static-text role does not by itself announce
  to a screen reader's navigation that "Help" is a section heading over the
  topic list below it.
- **Label requirements**: Satisfied for the fixed heading — it always reads
  the literal string `"Help"` (**fixed-help-heading**). Per-topic labeling
  is a Group View's and an Explanation View's responsibility, not this
  file's; the Explanation View's own recipe
  (`adtoolkit://cookbook/ui/settings/layout/explanation-view`) covers
  its label behavior.
- **Announce state changes (e.g., loading, disabled)**: The content-setting
  operation tears down and rebuilds the entire scrolled panel with no
  accessibility notification and no explicit focus move to the new content
  anywhere in source, so nothing announces to a screen reader user that the
  drawer's content just changed (e.g., when the reader switches settings
  panels and the drawer refreshes behind them).
- **Minimum tap target**: Not applicable — this component defines no
  button, control, or click handler of its own; it is a non-interactive
  content view. (The scroll view it hosts uses the platform's standard
  hit-testing, which this file does not customize.)
- **minimum-contrast-ratio**: The heading label's color is the active theme's primary text color, resolved as the theme's raw foreground color with no enforced minimum-contrast floor (unlike the secondary text role, which is dimmed toward the background); the component performs no contrast check of its own, so the heading's contrast against the window background is whatever each theme's colors produce.

