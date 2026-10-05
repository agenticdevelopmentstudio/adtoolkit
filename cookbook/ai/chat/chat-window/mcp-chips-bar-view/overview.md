
The MCP chips bar is a small header bar for an AI chat window: a server-rack
icon and a button reporting how many of the configured MCP servers are
currently active. Tapping the button opens a popover listing every available
server as a checkbox toggle, letting the user turn individual servers on or
off for the chat. The bar is not wired to any chat consumer yet — a separate
tool-loop component owns that integration, and the bar is retained for a
later phase when a consumer surfaces the registry selection UI again — so, as
shipped, it computes and reports active-server state faithfully but nothing
downstream currently reads that state (see Design Decisions).

