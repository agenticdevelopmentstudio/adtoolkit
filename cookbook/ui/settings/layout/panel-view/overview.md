
The Panel View is the root container for a settings panel: it hosts a
vertical stack of group-view cards, spaced apart inside the panel's
content area, per the source's own doc comment. It owns a single internal
vertical stack inset from its own edges by the panel's outer margin,
paints its own background from the active theme, and exposes exactly two
mutating operations: an add-group operation, which appends a group-view
card, and an add-heading operation, which appends a panel heading view
(constructed internally) ahead of the groups that follow it, widening the
gap above it so the heading reads as belonging to what comes after it
rather than as a caption trailing the card above — per the source's own
comment on that operation. Both the Group View and the Panel Heading View
are separate components with their own recipes; this recipe covers only
what this component itself does with them. The background color tracks
this component's own resolved theme scope rather than an app-wide default;
the source's own comment on that choice explains the color: "The same
ground as the sidebar and the window: the cards are what stand out here,
and a panel-shaped patch of a second near-identical colour behind them
only reads as a misprint."

