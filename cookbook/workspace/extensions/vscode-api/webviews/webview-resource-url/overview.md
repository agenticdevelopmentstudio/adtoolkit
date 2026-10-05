
This component defines the `agentic-webview` URL scheme that an extension's
webview panel loads from, and is the single place that decides whether a URL
in that scheme names something the panel is allowed to have. A webview runs
an extension's own HTML and JavaScript, so the page is hostile by assumption,
and it cannot be handed a local file location directly — a webview will not
load one from a custom-scheme document — so every resource is re-spelled as
`agentic-webview://<panel id>/<absolute file path>` and the scheme handler
asks the URL decision here whether a request for one may be answered. The
panel id is the URL's authority rather than a path segment specifically
because that is what makes two panels two separate origins; an empty path is
defined as the panel's own host document (its `webview.html` string) rather
than a file; and containment of a file path against the panel's declared
resource roots is delegated component-wise to the resource-path containment
check, the same rule that check's own recipe documents as this project's one
containment check, rather than a second implementation of it.

