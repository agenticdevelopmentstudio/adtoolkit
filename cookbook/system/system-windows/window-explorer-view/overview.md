
The window explorer is a reusable content view that lists
every running window, grouped into a section per owning application, each
with a selection checkbox. It is embedded by two callers that give it
different meanings: a discovery surface, where any visible window can be
checked, and a work-group direct-assignment surface, where windows already
belonging to the group being edited are toggled and windows owned by other
groups are shown but disabled. The view owns its own asynchronous window scan,
grouping, and Accessibility-based title enrichment; the caller only owns the
resulting set of selected window ids via a binding.

