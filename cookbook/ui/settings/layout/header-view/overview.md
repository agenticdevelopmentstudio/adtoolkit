
The Header View is a minimal view that wraps a single caption-styled label
pinned flush to all four of its own edges. It fulfills the same settings-
row-view contract as its siblings in this system. The sibling Group View
recipe documents its role directly: constructing a settings group from a
title builds a Header View as "a caption *outside* and above a rounded
card" — the label naming a settings group, sitting above the group's card
rather than inside it as a row. It is also constructed directly elsewhere in
the app to caption a settings subview. The Header View itself draws nothing
and holds no theming logic of its own; all appearance (color, font,
single-line clipping) comes from the label it wraps.

