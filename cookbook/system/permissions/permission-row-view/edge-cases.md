
- **Null/empty input** (MUST): the Automation permission targeting an empty
  bundle identifier — the platform's own app-name resolution returns
  nothing for the empty string, so the target-name lookup's fallback
  returns the bundle identifier string itself (here, empty). The title
  MUST render as `"Automation — "` and the Automation sentence in the
  description MUST render with an empty target name, rather than crashing.
  The Keychain permission for an empty service takes a different path: the
  title-building logic only special-cases Automation, so the title MUST
  still render as plain `"Keychain"` (the permission's display name),
  unaffected by the empty service; the description MUST render as the
  literal sentence with an empty quoted service name (`Lets this app read
  the "" item in your keychain directly, instead of asking another tool for
  it.`), rather than crashing or omitting the quotes.
- **Boundary values** (MUST): an unusually long explanation string MUST
  wrap across multiple lines in the description label (a wrapping text
  field with no line limit set), and the row MUST grow taller than the
  72pt floor to fit it, since its height constraint is a minimum, not a
  fixed height.
- **Concurrent access** (SHOULD): two overlapping refresh calls on the same
  row, neither cancelling the other — the component performs no internal
  serialization of overlapping refreshes, so which call's status result
  resolves last, and therefore which result the displayed state ends up
  showing, is left undefined by this component itself; each status-apply
  call simply overwrites whatever the previous one set. Coordinating that
  ordering SHOULD be the caller's responsibility (as the panel that
  composes these rows does with its own single refresh task), not this
  component's.
- **Error states**: Not applicable — the status-checking contract is
  declared non-throwing and returns a status value directly; undetermined
  already exists to mean "can't currently tell" (for example, an
  Automation target that isn't running), so there is no separate
  failure/error path for this component to render beyond the three states
  already specified.
- **Offline/disconnected state**: Not applicable — this component and its
  status checker read only local system authorization state; the component
  makes no network call, so connectivity has no defined effect on it.

