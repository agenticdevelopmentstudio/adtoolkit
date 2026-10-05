
This is the state and transport logic for the direct-message inbox, a single direct-message
thread, starting a direct message, the unread-count badge, and the notification inbox list. The
DM logic and the notification logic carry the same shape — state backed by a shared authenticated
request client, kept live over a shared live-connection transport, which authenticates over a
token carried by the connection itself plus a self-healing interval-and-window-focus poll
fallback. The notification logic additionally owns ONE process-wide "wake" channel — a single
refcounted live connection to the notification stream endpoint and a broadcast/subscribe pair —
that the DM logic reuses rather than opening its own parallel signal. It is headless **logic**
with no visual surface, so this recipe marks Appearance, States, and Accessibility not applicable
and carries the entire runtime contract in Behavioral Requirements, per the non-UI component
guidance this recipe was authored under.

