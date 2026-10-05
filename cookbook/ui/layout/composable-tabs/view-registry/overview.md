
The view registry maps a view id to a descriptor (the pane facts a split
needs before it has content — display name, icon, preferred axis, minimum
thickness, preferred thickness fraction, collapsibility, holding priority)
and a factory that builds the content a pane hosts for that id. It is an
**instance**, not a namespace of statics, because two different projects in
the same process (a demo project and a real app project, per the source's
own comment) need different view sets, and a single global registry would
let the last registrant win. Each project reaches its own instance through
its composable-tabs layout.

The same concept defines two supporting capabilities pane content may
optionally adopt — a teardown capability (release live resources, such as a
child process or a file watcher, the moment a pane closes) and a removal-
confirmation capability (say what would be lost if the pane were closed, or
nothing for nothing lost) — and the placeholder pane, the numbered, tinted
rectangle shown both for the registry's own reserved `placeholder` entry
and for any view id the registry has no entry for.

The registry itself renders nothing; the placeholder pane is the only
visual content this concept owns, and the Appearance/States/Accessibility
sections below describe that view. Everything else a pane's chrome shows
(title bar, gear menu, split behavior) belongs to the pane view and the
tabbed content view, which consume this registry but are out of scope for
this recipe.

