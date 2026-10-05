
**Decision**: The window declares its commands instead of the settings panel.
**Rationale**: The source's doc comment says the panel "is shared and knows
nothing about conversations" and only the window can perform the commands.
**Approved**: pending

**Decision**: The controller is resolved when a command runs, not when the
section is installed.
**Rationale**: The source's doc comment says binding to a live instance would
list the commands only for someone who had already opened the window, "the
wrong way round: the panel is where you go to find out what the app can do."
**Approved**: pending

