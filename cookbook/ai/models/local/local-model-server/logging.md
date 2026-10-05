
Not applicable: this component performs no logging. Both a whole-response
decode failure and each per-entry decode failure inside the response parser
are discarded with no diagnostic emitted — see
parse-sizes-whole-decode-failure-empty and parse-sizes-per-element-tolerance
in Behavioral Requirements, which is a deliberate choice per the component's
own stated design (one malformed entry is skipped rather than discarding the
whole listing, which would fail the guard open server-wide), not an
omission.

