
The Rdid Picker is a modal search picker for the identifier registry: it
opens a single-field, keyboard-driven search interaction, debounces what
the caller types, calls a caller-supplied search function, and hands back
the whole matched option (`rdid`, `entityType`, `entityId`) when one is
chosen. It is built directly on a shared modal command-search interaction
rather than beside it, because a modal over one field with a
keyboard-driven, first-result-preselected list is already the interaction
that shared component provides; the picker contributes only what a
search-backed instance of that shape still needs: the debounce, the
abort-on-supersede, the group/label/placeholder wiring, and resetting
itself when closed. It owns no opinion about which entities are
searchable — the caller's search function decides that, so restricting
the picker (to one ecosystem, say) is the caller's filter, not a prop
this component interprets.

