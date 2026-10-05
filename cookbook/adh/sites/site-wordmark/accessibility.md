
- Text-only and non-interactive; the brand and identity are read in document
  order by assistive tech.
- Color MUST come from theme token roles (the gold accent role, the primary
  text role, the dimmed text role), never a hardcoded value, so contrast tracks
  the active theme's semantic color roles rather than a value this component
  owns; the accent word carries meaning through text, not color alone (it is
  the site name).
- Carries no landmark role of its own — the consumer places it within its own
  heading structure (e.g. above the page's main heading).
- **theme-owned-contrast**: The wordmark and tagline text colors MUST resolve from the active theme's gold, primary-text and dimmed-text roles against the hosting background at runtime; the component performs no contrast check of its own, so contrast is whatever the active theme's resolved pair provides.

