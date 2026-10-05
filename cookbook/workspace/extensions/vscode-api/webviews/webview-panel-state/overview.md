
This component is the encoding of everything needed to put an extension's
webview panel back after a quit, as the single, optional string value the
pane-state store holds per key. Per the source's own documentation, that
store holds one opaque string per key, so every caller wanting structure has
to encode its own JSON; this component is that encoding, written once rather
than re-derived at each call site, because getting it subtly wrong is how a
panel comes back with a value its owning extension never saved. The panel
view produces a value of this component from its own restoration-state value
and consumes one when restoring itself; the panel serializer is what
actually performs the encoding before a pane-state write and the decoding
after a pane-state read, but neither of those calls belongs to this
component's own contract, which is the encode/decode round trip and the four
fields it carries: `viewType`, `title`, `state`, and `options`.

