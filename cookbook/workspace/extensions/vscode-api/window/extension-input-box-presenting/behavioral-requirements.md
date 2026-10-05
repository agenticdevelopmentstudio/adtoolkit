
- **severity-case-set**: the validation severity type MUST declare exactly
  three cases — information, warning, and error — corresponding to VS
  Code's `InputBoxValidationSeverity` values `Info` (1), `Warning` (2), and
  `Error` (3).
- **severity-case-naming**: the three case identifiers MUST use this
  project's own lowercase-noun spelling (information, warning, error)
  rather than transcribing VS Code's `Info`/`Warning`/`Error` member names
  verbatim.
- **severity-no-ignore-case**: the validation severity type MUST NOT
  declare a case corresponding to VS Code's internal ignore-severity value;
  the "nothing to show" outcome MUST instead be represented by the absence
  of a validation result rather than by a fourth severity case.
- **severity-value-semantics**: the validation severity type MUST be safe
  to pass across concurrent contexts and MUST support equality comparison.
- **validation-fields**: the validation result type MUST expose exactly two
  fields, a message text and a severity value, and MUST be safe to pass
  across concurrent contexts and support equality comparison.
- **validation-explicit-construction**: the validation result type MUST
  expose a constructor naming both fields explicitly, so a value is
  directly constructible from outside the declaring module.
- **validation-severity-always-attached**: a severity value MUST only ever
  be attached to a validation result whose message exists; there MUST be
  no representation of a severity with nothing to show.
- **request-fields**: the input-box request type MUST expose exactly eight
  fields — an optional title, an optional prompt, an optional placeholder,
  a non-optional pre-fill value, an optional value-selection range, a
  password flag, a focus-out-ignoring flag, and a validating flag — and
  MUST be safe to pass across concurrent contexts and support equality
  comparison.
- **request-explicit-construction**: the input-box request type MUST expose
  a constructor naming all eight fields explicitly, for the same reason the
  validation result type does.
- **request-value-non-optional**: the pre-fill value field MUST be a
  non-optional string; a call that supplied no pre-fill value MUST be
  represented as an empty string, never as an absent value.
- **request-value-selection-absent-means-whole-value**: an absent
  value-selection MUST mean the whole pre-filled value is to be selected.
- **request-value-selection-empty-means-cursor-only**: a value-selection
  range whose lower and upper bounds are equal MUST mean only the cursor is
  to be positioned, with no text selected.
- **request-value-selection-unit**: the bounds of the value-selection range
  MUST be interpreted as user-perceived character (extended grapheme
  cluster) offsets into the pre-fill value, not UTF-16 code-unit or byte
  offsets, because the JavaScript values this field is built from count
  UTF-16 code units while this field counts user-perceived characters.
- **request-is-validating-independent-field**: the validating flag MUST
  record, as its own field, whether the originating call carried a
  validation function at all; it MUST NOT be derived by a presenter
  invoking the validate function once to see what it does.
- **presenter-thread-confined-isolation**: the presenting role MUST be
  confined to a single execution context and MUST be usable only by
  reference types; every implementation's stored-property access and the
  synchronous portion of every method MUST execute within that confined
  context.
- **presenter-single-requirement**: the presenting role MUST declare
  exactly one requirement: presenting an input box, given a request and a
  validate function, and returning an optional resulting string
  asynchronously.
- **presenter-dismissal-vs-empty-value**: presenting an input box MUST
  return an absent result to mean the user dismissed the input box, and
  MUST return an empty string only to mean the user affirmatively accepted
  an empty value; an implementation MUST NOT collapse these into the same
  return value.
- **presenter-error-severity-blocks-accept**: an implementation of the
  presenting role MUST NOT resolve the presentation with a value whose most
  recent call to validate answered a validation result with error severity.
- **validate-return-contract**: the validate function a presentation is
  given MUST answer an absent result to mean the candidate value is valid,
  and MUST answer a present validation result to report a message,
  blocking acceptance when its severity is error, per
  **presenter-error-severity-blocks-accept**.
- **validate-absent-when-not-validating**: when the request's validating
  flag is false, the validate function MUST always answer an absent result
  regardless of the candidate string passed to it.
- **validate-non-optional-parameter**: the validate parameter given to a
  presentation MUST always be a callable function, never itself absent,
  even for a request where the validating flag is false, so every
  implementation follows one calling code path rather than branching
  between an absent function and a present one.
- **presenter-isolation-not-concurrency-safe**: the presenting role MUST
  NOT be declared safe to pass across concurrent contexts; an
  implementation's confinement to its single execution context is enforced
  by the confinement declared on the role itself, not by any
  concurrency-safety marker.
- **cross-call-ordering-left-to-conformer**: the presenting role MUST
  impose no ordering, queuing, or replacement policy of its own for a
  second presentation call issued on the same implementation before a
  prior call's returned value has settled; that decision is left to each
  implementation. The picker presenter, the production implementation
  named in this file, states its own replacement rule for an overlapping
  request outside this component, rather than queuing.
- **no-side-effects**: none of the validation severity type, the
  validation result type, the input-box request type, or the presenting
  role's declared members perform file I/O, network access, process
  launch, or persistence of any kind; the component imports only
  foundational, non-UI, non-networking facilities and declares no
  side-effecting code of its own — every side effect belongs to whatever
  implements the presenting role.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

