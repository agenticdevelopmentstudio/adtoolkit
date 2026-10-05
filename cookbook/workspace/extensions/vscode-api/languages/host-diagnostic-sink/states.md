
Not applicable — this is the extension host's diagnostic-change notifier, not a visual component. It has no lifecycle of its own beyond existing between construction and the extension host's teardown; the per-window state machine that follows a fire call belongs to the shared event emitter and is documented in the `extension-host-vs-code-api-extension-event` ingredient.

