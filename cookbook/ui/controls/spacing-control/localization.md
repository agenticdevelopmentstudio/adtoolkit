
Every user-facing string below is a literal assigned to a tooltip, title,
or accessibility description — never routed through a localization lookup
— so none of them can be localized without a source change; each would
need a localization key routed through this app's existing localization
mechanism, the same way any other user-facing string in the framework is
externalized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal) | "Top" / "Left" / "Bottom" / "Right" | An edge's display name, used inside every edge's field/arrow tooltip |
| (none — literal) | "{Edge} — points between the edge and what is inside it" | Tooltip on an edge's number field and stepper |
| (none — literal) | "More {edge} space" / "Less {edge} space" | Tooltip, and the arrow image's accessibility description, on an edge's grow/shrink arrows |
| (none — literal) | "side-by-side panes" / "stacked panes" | A gutter's display name, used inside a gutter's arrow tooltip |
| (none — literal) | "Points between two panes side by side. The gap is shared, so this is the whole gap." / the row-stacked equivalent | Tooltip on a gutter's number field and stepper |
| (none — literal) | "Narrower gap between {panes}" / "Wider gap between {panes}" | Tooltip, and accessibility description, on a gutter's narrow/wide arrows |
| (none — literal) | "Reset" | Reset button title |
| (none — literal) | "Set every number here back to zero" | Reset button tooltip |

