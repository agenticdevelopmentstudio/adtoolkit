
The record detail panel is the settings pane that shows one record in a window
whose sidebar lists records. It holds the record, keeps the sidebar row's title
equal to the record's title, and reports every accepted edit through a single
save callback. It never writes the record anywhere itself, so a refused save is
handled once, by the window's owner, rather than once per field. A concrete pane
builds its cards, passes each edited record to the panel's commit operation, and
names the field that should take the cursor when the record is newly added.

