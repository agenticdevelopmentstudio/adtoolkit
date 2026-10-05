
This component is the pure string-assembly layer that turns an extension's
`webview.html` into the document a webview actually loads. It has no visual
surface of its own: building the host document takes the extension's HTML
exactly as assigned and the JSON text of the panel's last persisted state,
and returns one document string with a `<script>` bootstrap injected
immediately after the opening `<head>` tag (or prepended, when no head can
be located with certainty). That bootstrap implements the page-side half of
the bridge: `window.acquireVsCodeApi()`, `postMessage`, `getState`, and
`setState`, wired to a single named message channel identified by a fixed
channel name. Because `webview.html` is a string an extension assigns and
nothing validates as well-formed markup, this component makes no assumption
about its shape — a fragment, a headless document, or an empty string must
all still come back with a working bridge — and because the state it embeds
was authored by the extension, the escaping this component performs before
embedding it is a security boundary against that state breaking out of the
`<script>` element it is placed inside, not a convenience.

