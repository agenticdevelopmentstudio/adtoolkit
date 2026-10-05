
- **renders-single-command-palette**: The component MUST render exactly
  one command-palette instance, passing it the open state, an open-state
  change callback, the query text, a query-change callback, one result
  group, an accessible label, a placeholder, a loading flag, an error
  message, and an empty-results label, and MUST implement no dialog,
  listbox, or keyboard handling of its own.
- **resets-on-close**: When the open state transitions to closed, the
  component MUST clear the query text to empty, the result list to
  empty, the error message to none, and the loading flag to false.
- **skips-search-for-empty-query**: While open and the trimmed query text
  is empty, the component MUST set the result list to empty, the loading
  flag to false, and the error message to none, and MUST NOT call the
  search function.
- **sets-loading-before-debounce-elapses**: While open and the trimmed
  query text is non-empty, the component MUST set the loading flag to
  true immediately, before the debounce delay elapses.
- **debounces-search-call**: The component MUST wait a configurable
  delay (default 200 milliseconds) after the last query change before
  invoking the search function with the trimmed query text, never the
  raw, untrimmed string.
- **aborts-superseded-search**: When the open state, the query text, or
  the debounce delay changes while a previously scheduled or in-flight
  search call has not yet settled, the component MUST cancel that call
  and MUST cancel its pending debounce timer.
- **ignores-aborted-search-results**: When a search call settles after it
  has been canceled, the component MUST NOT update the result list, the
  error message, or the loading flag from that settlement.
- **populates-options-on-success**: When a non-superseded search call
  resolves, the component MUST set the result list to the resolved
  array, MUST set the error message to none, and MUST set the loading
  flag to false.
- **surfaces-search-rejection**: When a non-superseded search call
  rejects, the component MUST set the error message to the rejection's
  message when the rejection is an error object, or to the literal
  string `"Search failed"` otherwise, MUST set the result list to empty,
  and MUST set the loading flag to false.
- **calls-latest-search-implementation**: Each debounced invocation MUST
  call the most recently supplied search function, even when the
  debounce mechanism has not been reset since the search function last
  changed identity.
- **passes-full-option-to-onPick**: Selecting a result MUST invoke the
  pick callback with that result's complete option (`rdid`,
  `entityType`, `entityId`), not the `rdid` string alone.
- **closes-on-pick**: Selecting a result MUST close the picker. The
  picker triggers no close of its own on selection — closing happens
  inside the composed command palette's own commit action, which fires
  the open-state change callback (closing the picker) before invoking
  the item's selection handler (and therefore the pick callback).
- **labels-group-by-entity-type**: The single result group's label MUST
  read `<entityTypeLabel> addresses` when an entity type label is
  supplied, and MUST read `Addresses` when it is not.
- **derives-default-placeholder**: When no placeholder is given, the
  search field's placeholder MUST read `Search <entityTypeLabel>
  addresses…` when an entity type label is supplied, and `Search
  addresses…` when it is not.
- **derives-empty-label-from-query**: The empty-results label MUST read
  `Start typing an address` while the trimmed query text is empty, and
  MUST read `No matching address` once the trimmed query text is
  non-empty.
- **defaults-title-and-aria-label**: The component MUST default its
  title to `Choose an address` and MUST pass that title through as the
  composed command palette's accessible label.
- **renders-each-result-by-rdid-with-badge**: Each item in the rendered
  group MUST use the option's `rdid` as both its item identifier and its
  label, and MUST show the option's `entityType` as the item's badge.

