
This component is a drop-in settings panel: it builds one permission row
per permission it is given, wires each row's grant action through a shared
presenter, and keeps every row's live status current by refreshing when
the panel first appears, whenever the host application reactivates (for
example, the user returning from system settings), and after a row's grant
action completes. It runs no polling timer of its own and is free of any
settings-framework dependency, so any app or window can host it.

