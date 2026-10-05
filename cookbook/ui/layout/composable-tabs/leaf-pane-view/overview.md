
The composable-tabs leaf pane is one leaf of a composable-tabs split tree:
registry-vended content under a pane title bar, plus — while arrange mode is
on — a dimming scrim and a small toolbar that let the user reshape the
layout around it.

It builds on a shared pane concept that owns the common chrome — the title
bar, the gear button, the minimize/zoom/close controls, and per-pane
spacing — for every kind of pane in the framework, not only composable-tabs
leaves. That shared pane chrome is out of this recipe's scope; only the
three things this leaf adds are documented here: which registry vends its
content, the backdrop that draws the active-pane outline, and what arrange
mode does over the top of an otherwise ordinary pane. The layout can be
rearranged two ways that answer different needs: the gear menu always
carries a Move submenu for a user who knows exactly which pane goes where,
and arrange mode dims the content and puts the same four directions in a
central toolbar for a user who is looking at the window deciding. Both read
the same underlying move-menu source, so there is one answer to what Move
means.

