
The given implementations hardcode English user-facing strings rather than localizing them:

- Error messages — `"You need to sign in again."`, `"You don't have permission to do that."`,
  `"That item no longer exists."`, `"The hub can't be reached right now."`, and the templated
  `"Connection problem: <detail>"` / `"Something went wrong: <detail>"`.
- The unavailable-facet notice — `"Not available in this version"`, shown for every unsupported
  facet.
- The slug pattern's validation message — `"Use lowercase letters, numbers and hyphens."`
- The facet rail's field labels, placeholders, and confirmation text (e.g. `"New Persona"`,
  `"Delete persona"`, `Delete persona "<name>"? This cannot be undone.`, and field placeholders
  such as `"Bob"`, `"bob"`, `"A one-line summary of this persona."`) are all English literals with
  no localization mechanism in these implementations.
- The demo-preview, chat-status, and demo-eligibility logic carries no user-facing strings of its
  own — its outputs are rendered by a presentation layer this recipe does not own — except the
  built-in chat-status word presets' English word pairs (`"thinking"`, `"responding"`, etc.),
  which are persisted author-facing content, not chrome.

