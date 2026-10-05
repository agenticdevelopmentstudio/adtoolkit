
**Decision**: URL-shaped fields decode every URL-shaped value as a plain
string, never as a parsed URL, with each computed accessor (icon, digest,
universal download, and the rest) parsing its own key lazily.
**Rationale**: The source's own top-of-file doc comment states the reason
directly: a parsed-URL type's decoding conformance throws on a string it
cannot parse, which would mean one extension with a malformed icon URL
takes down the decode of the whole search page it appeared in. Decoding as
a string and parsing per-accessor means a bad URL costs exactly the
accessor that reads it.
**Approved**: pending

**Decision**: That per-accessor URL isolation does not extend to the search
page's extension list as a whole — a search entry missing a required field
still sinks the entire page's decode, with no per-element recovery of the
kind the extension manifest's lenient decoding implements for its
contribution collections.
**Rationale**: The source's stated protection is scoped to URL-shaped
fields specifically, via computed accessors; the array itself is decoded
through the platform's ordinary synthesized decoding with no custom decode
logic anywhere in the search entry or search page types (Swift/AppKit
implementation). This is a real, narrower guarantee than a reader might
infer from the doc comment's framing around "one row's bad icon URL does
not take the page with it" — that sentence is true only for the icon URL
and its siblings, not for a structurally malformed entry.
**Approved**: pending

**Decision**: The installability verdict checks `targetPlatform` before
checking whether a universal download exists, and checks download existence
before the engine-range gate.
**Rationale**: The source's own doc comment states the check runs "before
the download rather than after, because every refusal here is knowable from
metadata alone and a user who is going to be told 'no' should be told before
several megabytes cross the network." The reference test suite's
platform-first-ordering test pins the platform-first ordering explicitly,
noting a platform-specific build "refuses before the engine is even read" —
this is a tested contract, not incidental code order.
**Approved**: pending

**Decision**: The installability verdict is a concurrency-safe,
equality-comparable value with one named case per refusal reason, rather
than a flag paired with a freeform message string.
**Rationale**: The source's own doc comment names the reason: a settings UI
"has to say which wall an extension hit" — "needs VS Code 1.140" and "ships
a macOS binary" are different situations with different answers — and a
reason assembled as prose at the point of refusal "cannot be tested or
localized." The comment names this explicit-over-implicit.
**Approved**: pending

**Decision**: An extension detail's engine range collapses "no
`engines.vscode` key" and "an `engines.vscode` value that fails to parse"
into the same absent result, even though the installability verdict treats
those two situations differently (ungated vs. "engine range unreadable").
**Rationale**: The property's own doc comment states plainly that "an
extension with no `engines.vscode` is not gated — see the installability
verdict," pointing the reader at the one place that does draw the
distinction. The engine-range accessor is a convenience for callers that
only need the parsed range when one exists; the absent-vs-unreadable
distinction is deliberately implemented once, inside the installability
verdict, rather than duplicated at this property.
**Approved**: pending

