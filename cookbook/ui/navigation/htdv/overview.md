
This is the non-UI logic that a hierarchical topic detail view's
presentation layer renders: it owns no view and draws nothing. It is four
cooperating pieces:

- **The navigation controller** - a UI-thread-confined navigation/selection/
  loading state machine that walks a data source's tree one level at a time
  and exposes the levels, selection, detail, loading level index, and error
  to a host view.
- **The data model** - an item, a level, a detail destination, a child
  (what lies beneath a selected path), a badge, a create action, the
  data-source contract the host implements, and the row projection, the
  platform-neutral row shape every rail cell renders from.
- **The layout engine** - a pure function from available width, level
  count, and compactness to a rails-vs-stack layout mode, called by the
  presentation layer on resize.
- **The forms subsystem** - the declarative shape of a detail form (the
  form specification), its field value type, its mutable, dirty-tracked,
  save-lifecycle model (the form model), and its per-field validation rules
  (the validator).

The markdown editing contract is included because it is the injectable
factory contract the forms subsystem's markdown field kind depends on; its
default implementation is itself logic (text in, text out via a callback)
even though the concrete editor/viewer it vends are platform view
controllers - see Design Decisions.

The presentation layer that consumes this engine is out of this recipe's
scope and is not described here except where a requirement below states
what the presentation layer is responsible for.

