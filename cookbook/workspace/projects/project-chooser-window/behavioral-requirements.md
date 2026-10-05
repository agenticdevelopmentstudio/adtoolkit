
- **coordinator-required-no-default**: Constructing the chooser window and
  its choose-and-callback entry point MUST both require a
  coordinating-component argument with no default value, and the entry
  point MUST NOT construct a chooser window or a coordinating component any
  other way.
- **window-identity-fixed-at-init**: Constructing the chooser window MUST
  create exactly one window sized 460×480, closable and resizable with a
  title bar, titled "Open Project", with a minimum size of 360×300, and
  MUST set that window as both the controller's own window and as the
  target of its own close notifications.
- **content-view-controller-fixed-at-init**: Constructing the chooser
  window MUST construct exactly one content view for the given
  coordinating component and MUST assign it as the window's content.
- **browser-constructed-in-chooser-mode**: Constructing the content view
  MUST construct its hosted project browser in chooser mode.
- **onchoose-single-invocation**: The choose-and-callback entry point MUST
  call its callback exactly once, with the repository record the modal
  session returns, and only when that result is present; when the modal
  session ends with no result (the user cancelled), the callback MUST NOT
  be called at all.
- **runmodal-return-value**: Running the modal session MUST return the
  chosen repository record after the session ends; the chosen value is
  absent unless the finish step was invoked with a present repository
  record at some point during that session.
- **content-onfinish-drives-outcome**: The window's eventual outcome MUST
  be determined entirely by invocations of the content view's finish
  callback, which is wired at the end of construction to call the window's
  own finish step; that finish step MUST assign its argument to the chosen
  value and MUST end the modal session.
- **open-button-forwards-current-selection**: Activating the Open button
  MUST call the finish callback with the browser's currently selected
  repository, forwarding whatever the browser reports at the moment the
  button is activated, not a value captured earlier.
- **cancel-button-forwards-nil**: Activating the Cancel button MUST call
  the finish callback with no repository, unconditionally, regardless of
  the browser's current selection.
- **browser-onchoose-forwarded-unchanged**: The browser's own choose
  callback MUST be wired, at construction, to call the finish callback with
  the exact repository record the browser passes, forwarding it unchanged;
  the conditions under which the browser itself invokes its choose callback
  (double-click, Return) are the browser's own contract, not this dialog's.
- **open-button-enablement-tracks-selection**: The browser's
  selection-change notification MUST be wired, at construction, so that
  every reported selection change enables the Open button when the
  reported repository is present and disables it when absent.
- **open-button-initial-disabled-then-synced**: The Open button MUST be
  explicitly disabled while the view loads, before the browser's view is
  created; creating the browser's view for the first time a few moments
  later synchronously loads the browser, which reports its own initial
  selection through the selection-change notification — so the Open button
  MUST end view loading reflecting the browser's initial selection, not the
  disabled value assigned moments before.
- **window-close-ends-session-as-cancel**: The window's close notification
  MUST call the finish step with no repository whenever the closing window
  is the one currently treated as the active modal window, which is how
  dismissal via the title bar close control or the primary close shortcut —
  both of which bypass Cancel and Open — MUST still end the session.
- **window-close-ignored-when-not-active-modal-session**: The window's
  close notification MUST NOT call the finish step (and therefore MUST NOT
  end the modal session) when the window is not identified as the active
  modal window; per the design rationale, this ends "only end a session we
  are in".
- **runmodal-orders-out-without-closing**: Running the modal session MUST
  bring the window to the front and make it key before entering the modal
  loop, and MUST order the window out immediately after the modal loop
  returns; per the design rationale, this ordering-out step MUST NOT itself
  produce a close notification, so it MUST NOT trigger the window-close
  handling.
- **runmodal-activation-respects-quiet-presentation**: Before showing the
  window, running the modal session MUST activate the application unless
  quiet presentation is enabled, in which case activation MUST be skipped
  entirely.
- **stock-buttons-fixed-key-equivalents**: Creating the view MUST create
  Cancel and Open as native platform buttons with a standard push-button
  appearance, MUST set Cancel's key equivalent to Escape and Open's key
  equivalent to Return, and MUST route Cancel's action to the cancel step
  and Open's action to the open step.
- **accessibility-identifiers-fixed**: The chooser window MUST set the
  accessibility identifier "project-chooser.window" on its window,
  "project-chooser.cancel" on the Cancel button, and "project-chooser.open"
  on the Open button.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

