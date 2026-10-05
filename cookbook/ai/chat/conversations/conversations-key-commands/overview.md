
The Conversations window's key commands are declared by the window, not by
the settings panel that lists them. The panel is shared and knows nothing
about conversations, and only the window can actually perform them. This
component produces one section of command descriptors that the key-command
registry installs. The registry's single app-wide key monitor performs the
commands; each one asks the live window controller whether the keystroke is
its to take (the Conversations window is key, and the caret is not in a text
field) and passes the key on when it is not. The controller is resolved when
a command runs, not when the section is installed, so the host can declare
the commands at launch, before any Conversations window exists, and the
settings panel lists what the app can do even for a person who has never
opened that window.

