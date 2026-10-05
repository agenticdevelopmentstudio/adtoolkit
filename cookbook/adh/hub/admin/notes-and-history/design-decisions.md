
- **Decision**: Give notes and history independent loading flags
  (`notesLoading`, `historyLoading`) rather than one combined loading
  flag.
  **Rationale**: The source comment states each section "has its own loading
  flag — a slow history fetch never withholds already-loaded notes." A
  single shared flag would force both sections to wait on the slower of
  the two fetches.
  **Approved**: pending
- **Decision**: Keep the component purely presentational, with no internal
  data fetching, caching, or state management.
  **Rationale**: The source comment states "the caller fetches the data
  (react-query lives in the app, never here)." This keeps the block reusable
  by any caller regardless of its data-fetching strategy.
  **Approved**: pending
- **Decision**: Render admin notes as bordered/background cards
  (`rounded-md border ... bg-apt-surface-2/40 p-2`) while history entries
  render as plain, unstyled text lines.
  **Platform**: React/Web.
  **Rationale**: Notes carry free-form, user-authored content that benefits
  from a visually distinct container; history entries are terse, uniform
  log lines that read better as a compact, unadorned list.
  **Approved**: pending
- **Decision**: Fix each section's heading at `<h4>` rather than exposing a
  configurable heading-level prop.
  **Platform**: React/Web.
  **Rationale**: Source hardcodes `<h4>` for both "Admin notes" and
  "History" with no prop controlling it; the component is always composed
  as a sub-section of a larger detail panel, so its heading depth is
  assumed rather than negotiated with the caller. Accessibility tradeoff:
  a caller whose surrounding structure doesn't already place an `<h3>`
  (or shallower) immediately above this block will produce a skipped
  heading level for assistive-technology heading navigation — see
  **renders-notes-section**/**renders-history-section**.
  **Approved**: pending

