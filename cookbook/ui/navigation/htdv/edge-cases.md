
- **Null and empty input**: Selecting an item id absent from the given
  level's items MUST no-op (MUST, see select-validates-membership).
  Setting a field's value for a key absent from the form's fields MUST
  no-op (MUST, see set-validates-the-changed-field-only). A required text/
  multi-line-text/markdown field with an empty or whitespace-only value
  MUST fail validation with an "is required" message; the same field,
  when optional, MUST pass with no error (MUST, see
  text-required-and-trims). An empty string-set field MUST fail
  validation only when required (MUST, see string-set-required).
- **Boundary values**: A number field's value exactly equal to its
  minimum or maximum MUST pass validation - the comparisons are strict,
  not inclusive-by-accident (MUST, see number-required-bounds-and-
  integer). Deciding the layout with a level count of `0` MUST return an
  empty visible-rails range, while any level count greater than `0` MUST
  return at least one visible rail (MUST, see zero-levels-shape,
  at-least-one-rail-when-levels-exist). A rail width of `0` or negative
  (settable after construction despite the construction-time check) MUST
  be clamped to a divisor of at least `1` rather than dividing by zero or
  a negative number (MUST, see rail-width-divisor-clamp). Jumping back to
  a level MUST treat `-1` as "clear everything" and anything below `-1`,
  or at/above the current depth, as a no-op (MUST, see
  pop-to-level-contract).
- **Concurrent access**: The navigation controller and the form model each
  serialize their mutable state onto a single execution context (see
  Platform Notes for the exact confinement mechanism), so their state
  cannot be touched concurrently from a different context without an
  explicit handoff. Overlapping asynchronous fetches on the same
  controller (a second selection/reload/load starting before an earlier
  one resolves) are not prevented outright; instead, each fetch's result
  is validated against a request counter captured when it began, and a
  result whose counter is stale is silently dropped rather than applied
  out of order (MUST, see stale-response-dropped). Setting a field's
  value on the form model while its own save is in flight is not blocked;
  it mutates the current values immediately, and the in-flight save's
  already-captured value snapshot is unaffected, which MUST leave the
  form dirty even after that save later succeeds (MUST, see
  concurrent-edit-during-save-stays-dirty).
- **Error states**: A thrown error from the data source's root-level or
  child fetch MUST populate the controller's error with the failing level
  index and a message derived from the error (or MUST be dropped silently
  if a newer request has since started) - it is never left unreported to
  a still-current caller (MUST, see error-shape). A thrown error from the
  save action MUST populate the form model's save error with a derived
  message and MUST leave the form dirty (MUST, see
  save-failure-preserves-dirty-state). The create action and the delete/
  extra actions have no channel of their own for the engine to observe or
  record a failure - see **create-action-error-path** below and
  delete-and-extra-actions-are-outside-the-save-lifecycle.
- **Offline or disconnected state**: Nothing in this scope makes a network
  call directly; the data source's root-level/child fetches are the only
  points where a network-backed implementation could fail, and that
  failure surfaces to the controller exactly like any other thrown error
  (see Error states above) - the engine defines no timeout, retry, or
  connectivity-aware behavior of its own around those calls (fact, not a
  gap: an absent feature, not a swallowed signal - the failure is not
  lost, it is reported as an error, just without a time bound).

- **create-action-error-path**: The create action's callback is declared
  to run on the UI thread, receive the hosting view controller, and
  complete with no return value and no ability to fail - so the engine
  defines no path for a creation failure to reach the controller's error
  or trigger a reload. The signature makes it the callback's own
  precondition to present and recover from its own failures without
  engine involvement.

