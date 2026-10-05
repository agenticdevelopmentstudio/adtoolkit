
**Decision**: The parse-to-object operation never accepts a top-level
scalar fragment from any of its parse attempts, but the
normalize-to-strict-JSON operation's own initial strict-JSON check does
accept one.
**Rationale**: (Swift/Foundation implementation) This creates an asymmetry
a reader would not expect from the two operations' names alone: normalizing
the bytes for `42` returns those bytes unchanged (the initial check accepts
a bare top-level number), but parsing the bytes for `42` to an object throws,
and a JSONC document whose root is a scalar (e.g. `42 // comment`) fails
through the normalize operation too, because its fallback is the
parse-to-object operation, which never accepts a fragment. Nothing in the
source comments this choice; it follows mechanically from the normalize
operation's passthrough check being written to allow fragments and every
other call site omitting that option.
**Approved**: pending

**Decision**: Candidate encodings are tried strictly in a fixed order —
UTF-8, UTF-16, UTF-16 big-endian, UTF-16 little-endian, UTF-32 big-endian,
UTF-32 little-endian — and the winner is the first candidate whose decoded
text also *parses*, not merely decodes.
**Rationale**: Per the source's own comment, UTF-16 bytes for ASCII text
also decode as UTF-8 (the interleaved NULs are valid UTF-8), and UTF-16
accepts any even-length payload as big-endian, so a "first that decodes"
rule would let an earlier candidate silently swallow a later one's file and
turn a good document into a syntax error. Requiring a successful *parse*,
not just a successful *decode*, is what makes the fixed try-order safe.
**Approved**: pending

**Decision**: The normalize-to-strict-JSON operation returns bytes that are
already strict JSON completely unchanged, rather than always round-tripping
through the parse-to-object operation and re-serializing.
**Rationale**: Per the source's own comment, a re-serialized document is
not byte-identical to the one that came in — `1e3` comes back as `1000`,
and key order can change — so a decoder that never sees the rewritten form
cannot be surprised by it. Only a file the strict parser actually refuses
pays the transform cost.
**Approved**: pending

**Decision**: The trailing-comma scanner blanks a disqualified comma by
overwriting it with a space character rather than removing it from the
text.
**Rationale**: (Swift/Foundation implementation) Per the source's own
comment, overwriting keeps every remaining character offset valid while the
single forward scan is still running; deleting the character would shift
every subsequent index and require either a second pass or index-adjustment
bookkeeping the current single-pass algorithm does not do.
**Approved**: pending

**Decision**: An unterminated `/* … */` block comment consumes the rest of
the document with no recovery attempt, producing a downstream parse failure
rather than a repaired document.
**Rationale**: The design makes no attempt to detect or recover from this
case; the test covering it states the intent directly: this is the honest
outcome for a file whose author left a comment open, not a defect to be
patched around.
**Approved**: pending

