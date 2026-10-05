
Three small, independent primitives that give an app AppleScript and
scripting-dictionary support without each app-shell reimplementing the same
cross-context bridging boilerplate. A script-running operation compiles and
executes an AppleScript source string and returns a structured result instead
of an unrepresentable failure. A command base is what a scriptable command
handler inherits from so its command-handling override runs on a single,
serialized execution context without each handler re-deriving that bridge by
hand. An element-locator helper builds the scripting locator a scriptable
wrapper returns for an element that hangs directly off the application (a
pane, tab, project window, or terminal session). All three live in one
scripting module and are re-exported through the toolkit's feature layer so
existing call sites keep working. The script-running operation depends only
on the platform's foundational, UI-free layer; the command base and the
element-locator helper additionally depend on the platform's UI framework.

