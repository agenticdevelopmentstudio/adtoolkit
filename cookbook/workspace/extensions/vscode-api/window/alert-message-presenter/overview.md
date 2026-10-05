
This component is the one production implementation of the message-presenting
role documented in [Extension Message Presenting](adtoolkit://cookbook/workspace/extensions/vscode-api/window/extension-message-presenting)
given among the sources: it turns a `vscode.window.show*Message` request into
a native alert attached to a window. Where the protocol recipe documents the
contract every implementation must satisfy, this recipe documents this
implementation's own presentation choices: always a window-attached alert,
attached to a window read fresh from an injected window-lookup function
rather than guessed at from ambient application state; never an
application-wide modal alert, because this is a background-only app with no
dock icon, for which activating unexpectedly would seize the screen from
whoever is typing; and, with no window anywhere in the app to attach an
alert to, the message is logged and dropped rather than shown by any means
that would seize the screen. The type also derives the button layout —
including which button carries the Escape key equivalent — from the
request's item titles and close-affordance indices, and reports, through
this project's shared logging convention, the one failure mode it can reach
on its own: a dropped, never-shown message.

