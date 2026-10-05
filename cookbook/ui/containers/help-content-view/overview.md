
This is the content of a help drawer: a fixed "Help" heading over an
independently scrolling list of help topics. Per the concept's own
rationale, the topics are ordinary Group View + Explanation View pairs — the
same two views the settings panels are built from — so help reads in the
same type and rhythm as the controls it describes. This recipe covers only
the heading-over-scroll-area view itself and its content-setting operation;
the sliding, the edge it comes out of, and the window tracking belong to the
drawer that hosts it. In the toolkit's own composable settings window, this
content is hosted inside a drawer controller that owns the drawer chrome and
feeds it the active panel's help content.

