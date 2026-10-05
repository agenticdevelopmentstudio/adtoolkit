
- **thread-confined-role-conformance**: this component MUST be confined to a
  single execution context, and MUST conform to the message-presenting role.
- **explicit-window-parameter**: constructing this component MUST take a
  window-lookup function with no default value, so a caller MUST make an
  explicit choice about which window (if any) an alert attaches to, rather
  than construction picking one implicitly.
- **injected-window-storage**: the injected window-lookup function MUST be
  stored privately, set once at construction and never reassigned.
- **window-queried-per-presentation**: resolving the presentation window
  MUST call the injected window-lookup function fresh on every invocation
  rather than caching its result at construction, so the answer reflects
  whichever window is frontmost at presentation time.
- **presentation-window-fallback**: resolving the presentation window MUST
  return the injected window-lookup function's value when it is present,
  and otherwise MUST return the value of selecting any visible window.
- **any-visible-window-selection**: selecting any visible window MUST return
  the first window, among those the app currently has, for which both
  visibility and eligibility to become the main window are true, and MUST
  return nothing when no such window exists.
- **window-attached-presentation-only**: presenting a request MUST present
  every request as an alert attached to the resolved presentation window.
- **no-app-activation**: presenting a request MUST NOT call an
  application-wide modal presentation, or any other presentation approach
  that activates the app or makes a window key when the app is not already
  active.
- **drop-when-no-window**: when resolving the presentation window yields no
  window, resolving the response MUST NOT present the alert by any means,
  and MUST resolve to nothing.
- **dropped-message-logged**: whenever resolving the response drops a
  message because no presentation window was found, it MUST log an
  error-level message under this component's own logging identity, and
  MUST NOT log anything when a window is found.
- **message-text-assignment**: presenting a request MUST set the alert's
  message text to the request's message unconditionally, including when
  the request's message is an empty string.
- **detail-text-conditional**: presenting a request MUST set the alert's
  detail text to the request's detail when it is present, and MUST leave
  the detail text at whatever default the native alert itself assigns when
  the request's detail is absent.
- **severity-style-mapping**: mapping a severity to an alert style MUST map
  the request's severity to the platform's alert-style vocabulary as
  information to informational, warning to warning, and error to critical,
  and presenting a request MUST assign that mapped value to the alert's
  style.
- **empty-items-single-ok**: when the request's item titles are empty,
  presenting a request MUST add exactly one button titled `OK`, MUST await
  its presentation, and MUST return nothing regardless of which response
  that presentation produces.
- **button-plan-skip-flagged**: for a non-empty set of item titles, planning
  the button layout MUST include, in item-title order, the index of every
  item whose index is not a member of the request's close-affordance
  indices.
- **button-plan-cancel-slot**: planning the button layout MUST append
  exactly one further entry after that skip pass: the last close-affordance
  index when the close-affordance indices are non-empty, or nothing
  (denoting a synthesized cancel button) when they are empty.
- **button-titles-from-plan**: adding the buttons MUST add exactly one
  button per button-plan entry, in plan order, titled with the
  corresponding item title for an entry naming an item index and titled
  `Cancel` for an entry denoting the synthesized cancel button.
- **escape-key-position-rule**: computing the Escape-key position MUST
  return the plan's last index when the plan has more than one entry, and
  MUST return nothing when the plan has one entry or is empty.
- **escape-key-assignment**: adding the buttons MUST assign the Escape
  character as the keyboard equivalent of the button at the position
  computing the Escape-key position returns, when that position is
  present, and MUST leave every other added button's keyboard equivalent
  at whatever default the native alert itself assigns it.
- **response-to-item-index**: on a non-empty-items alert, presenting a
  request MUST compute a button index by comparing the user's response
  against the platform's first-button response baseline, and MUST return
  the corresponding button-plan entry — itself nothing when that plan entry
  is the synthesized cancel button — as the call's result.
- **out-of-range-response-resolves-absent**: if the computed button index does
  not index into the button-plan entries, presenting a request MUST return
  nothing rather than access the entries out of bounds.
- **no-throwing-path**: presenting a request MUST NOT fail under any input
  or presentation outcome, matching the message-presenting role's
  non-failing requirement.
- **is-modal-not-honored**: presenting a request MUST NOT read or branch on
  the request's modal flag; every request MUST be presented as a
  window-attached alert regardless of that field's value.
- **logger-identity**: this component MUST log under its own name as
  category, with a subsystem derived from the app's own identifier (or a
  fixed fallback literal when unset), matching the shared logging
  convention this project's components use.
- **thread-confined-external-access**: a caller outside this component's own
  confined execution context MUST reach any of its operations only through
  an asynchronous call across that boundary.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

