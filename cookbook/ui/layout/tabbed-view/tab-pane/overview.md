
The component represents one session as a tab-bar item inside
[the tabbed view](adtoolkit://cookbook/ui/layout/tabbed-view). It
conforms to a stacked-item interface, so the hosting bar can tell it apart
from a plain title string: it carries selection (highlighted state) and how
far it stands from the selected tab (stack depth), and it draws itself as a
card in a deck rather than a flat label.

Its pane view is a self-contained card showing the agent's name and model,
live status glyphs, session name, working directory, branch, and an optional
summary. The card in front of the deck (depth `0`) paints the workspace's
own backdrop and outline and physically overhangs the bar's edge by one
point, fusing its outline with the workspace's so no seam is visible; every
card behind it recedes inward on every side - and, on a vertical bar,
recedes further the deeper it stands - reading as a deck of cards turned to
whichever one is selected. All content is supplied by a data source, fetched
only when the owner calls the reload operation; the pane never computes or
polls for its own content.

