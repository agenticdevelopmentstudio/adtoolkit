
Branch management owns one project checkout: its git status provider, its
live current branch, the tab panes that describe it, and the three
commands a command palette or a pane's context menu act on it through. It
is vended once per checkout and reused across branch switches of that same
directory; by design it "never touches the window." It is the tab pane's
data source (so the pane can render the checkout's agent, session,
directory, branch and summary without computing any of it itself) and its
context-menu provider (so the same component supplies the pane's context
menu). Every property and method is confined to a single execution context
(see Platform Notes).

