
- **Empty value** (empty string): renders the input empty; this is an
  ordinary controlled-value state, not a special case in the source
  (MUST, per **displays-controlled-value**).
- **Empty prefix** (empty string): renders one full-width input with the
  whole rdid editable, per the component's own documentation ("an empty
  string renders a single full-width input") (MUST, per
  **renders-single-input-without-prefix**).
- **Boundary values (leaf length/character set)**: not enforced by this
  component. The editor does not import the rdid grammar's
  character-set pattern or length limit; it relies entirely on the
  caller-supplied error (typically derived externally from leaf
  validation) to signal an invalid or over-length leaf (MUST, per
  **shows-error-in-place-of-hint** — the component's only lever over
  invalid input is displaying what it is told).
- **Mixed-case paste**: pasting `ACME-Org` into the input fires the same
  change handling as typing, so the full pasted value is lowercased
  before the change is reported, not just newly typed characters (MUST,
  per **lowercases-input-on-change**).
- **Uppercase character typed mid-value**: typing an uppercase letter in
  the middle of an already-lowercase value (e.g. inserting `A` into
  `acme` to get `aAcme`) still lowercases the whole value on the same
  change event (per **lowercases-input-on-change**); because the
  resulting controlled value differs from what was just displayed, the
  input's displayed value is resynced on the next render and the caret
  moves to the end of the field rather than staying at the edit point.
- **Concurrent access**: not applicable — the editor is a stateless,
  purely controlled view. It holds no value state of its own and
  performs no I/O, so there is no shared state for concurrent renders or
  events to race on.
- **Error states (dependency/network failure)**: not applicable — the
  source makes no network or storage calls; its only "error" is the
  caller-supplied error input, which is a display concern already
  covered under Behavioral Requirements, not a failure of a dependency
  this component owns.
- **Offline/disconnected state**: not applicable — the component
  performs no network operation of its own.
- **Caller-supplied identifier collision**: if a caller passes an input
  identifier that collides with another element's identifier elsewhere
  on the page, the component does not detect or guard against it — no
  such check exists in the source. Avoiding collisions is the caller's
  responsibility.

