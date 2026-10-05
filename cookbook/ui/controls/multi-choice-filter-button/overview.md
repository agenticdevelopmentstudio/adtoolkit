
This is a pull-down control that filters on any combination of a short,
fixed list of choices — the source's own doc comment gives the example
"the `Good for: Coding, Writing` control above a picker's table." Choices
are identified by opaque string ids rather than a caller's own enum, so one
control serves any caller's type without this file knowing about it; the
caller maps ids back to its own type. The button's displayed title is a
running summary of the current selection ("Any" when nothing is chosen, the
chosen titles when there are one or two, a count once there are three or
more), so the state is legible without opening the menu. Because the menu
is a stock, checkable menu, it closes on every pick — per the source's own
comment, several boxes take several trips, and the alternative (items
hosting their own checkbox views to keep the menu open) trades a familiar
system control for a hand-built one.

