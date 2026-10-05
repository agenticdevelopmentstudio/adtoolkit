
This is the scripting surface that answers everything the AppleScript scripting layer
asks about project windows, tabs and panes: three enumerated
lists (scriptable project windows, scriptable project tabs, scriptable
panes) and three id-based lookups, one per kind. It hangs off the project
window manager rather than a separate registry because that manager is
already the answer to "which project windows are open." Its one piece of
domain logic beyond enumeration is git: resolving each tab's working
directory to a live branch name by reaching through the project
controller's branch controller for that directory — the branch a project
tab's `branch` property exposes to a script. The surface itself constructs
three wrapper values it does not define — a scriptable project window, a
scriptable project tab, and a scriptable pane — whose own properties this
recipe also specifies, because no other recipe yet owns them.

