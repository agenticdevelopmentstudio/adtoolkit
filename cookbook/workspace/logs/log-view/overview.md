
This is a component that renders a scrolling, multi-column table of log
lines supplied by a caller-provided log provider. It builds its table
columns from the provider's columns at construction time, redraws whenever
the provider notifies it of an append, replace, or clear, and routes single-
and double-clicks on a cell to the hooks defined on that cell's column so
that domain logic (opening a session detail, copying an id, etc.) stays with
the consumer rather than the view. It deliberately ships no toolbar, filter
UI, or status indicator — those are caller concerns, composed around the
view (for example inside a hosting log-viewer controller) or embedded
elsewhere.

This component has no ingredient recipe of its own for the collaborator
types it takes; a consumer implementing them needs only this minimal
contract:

- **The log provider**: a settable delegate reference that this component
  assigns itself to at construction; a `columns` list, captured once at
  construction; a `lines` list, re-read on every table reload; and a
  `maxLines` limit, which this component never reads (row-count capping is
  the provider's own concern).
- **The log-provider delegate**: one method, called whenever the provider
  changes, with a change value that is one of: appended (with a count),
  replaced, or cleared.
- **A log column**: an `id` (the table column's identifier and the key into
  a log line's values), a `title`, a `defaultWidth`/`minWidth`/`maxWidth`,
  a text `alignment`, and optional `onClick`/`onDoubleClick` hooks.
- **A log line**: a set of values keyed by column id, where each value is
  either a plain string or a styled (attributed) text value; a column with
  no entry for a line renders as an empty string.
- **The themed label, table view, scroll view, and table-row view**: themed
  view types that resolve semantic theme roles (`.windowBackground`,
  `.primaryText`, `.selection`, `.divider`) to the active palette's
  concrete colors; this component only selects which role each one uses.

