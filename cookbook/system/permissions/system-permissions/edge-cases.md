
- **Empty automation bundle id** (MUST): an automation permission
  targeting an empty bundle identifier produces the token `"automation-"`;
  the probe returns whatever non-zero status descriptor creation or the
  permission check yields, which maps to undetermined (per
  **automation-mapping**).
- **Empty keychain service** (MUST): a keychain permission for an empty
  service produces the token `"keychain-"` and ledger key
  `"permission.keychain-.status"`; a read with an empty service is issued
  as-is.
- **Target app not running** (MUST): automation status for a quit target
  returns -600 and reads as undetermined, never denied.
- **No keychain item** (MUST): the request operation for keychain, for a
  missing item, returns undetermined and erases any ledger record.
- **Locked keychain or interaction not allowed** (MUST):
  `errSecInteractionNotAllowed` maps to denied and is recorded in the
  ledger as `"denied"`, even though the cause may be transient.
- **Ledger stale after revocation** (MUST): a user who later removes this
  app from the item's access-control list still reads granted from the
  status operation until the app performs a real read and records the
  new outcome.
- **Keychain service name collision**: distinct services that normalize
  to the same token share one ledger record (see
  **keychain-ledger-key-collision**).
- **Notification request throws** (MUST): the thrown error is discarded;
  the call returns the re-read status, so the failure surfaces only as
  denied or undetermined.
- **Location prompt closed without decision, Location Services off, or
  missing usage description** (MUST): the request operation for location
  returns after the 120-second timeout with the current status,
  typically undetermined.
- **Location read before the manager has synced** (MUST): the status
  operation for location can report undetermined on a freshly created
  coordinator; the single long-lived coordinator exists to limit this.
- **Concurrent location requests** (MUST): callers arriving while
  undetermined join the existing waiter list and timeout; all are
  resumed once with the same status.
- **Late delegate callback or timeout after resume** (MUST): resuming all
  waiters returns immediately when the waiter list is empty, so no
  continuation is resumed twice.
- **Cancellation** (MUST): neither the status operation nor the request
  operation observes cancellation of the caller's own asynchronous work;
  a cancelled caller still waits for the system dialog, the background
  read, or the 120-second location timeout.
- **Timeouts** (MUST): only location has a timeout. The automation probe
  with prompting allowed, and the first keychain read, block their
  background execution context for as long as the user leaves the dialog
  open.
- **Screen capture after refusal** (MUST): the request operation for
  screen capture returns denied with no dialog; recovery is via the
  settings pane.
- **Invalid pane URL string** (MUST): the settings-pane-location property
  traps with a precondition failure; with the fixed strings in source
  this does not occur.
- **Network or offline** (not applicable): no operation performs network
  I/O; keychain synchronization across devices is handled by the
  operating system.

