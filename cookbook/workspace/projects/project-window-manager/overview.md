
This keeps one window per open project, keyed by a repository's id rather
than by its path, so opening "the same project" twice after it has moved
or been renamed still raises the same window. For every project it opens
it builds a matched pair — a project controller that owns the
checkout/tab reconciliation, and a window controller that hosts it — and
tears both down together when the window closes. It conforms to the
project-opening interface so a coordinator can hand it project-open/close
requests, and it publishes changes so a browser can watch which projects
are currently open. Beyond the windows it opens itself, it can also adopt
a window a host built by some other means, so scripting can see it too,
and it restores whichever projects were flagged open when the app last
quit. It is confined to the UI's main execution context, and every
property and method is confined there by that declaration alone.

