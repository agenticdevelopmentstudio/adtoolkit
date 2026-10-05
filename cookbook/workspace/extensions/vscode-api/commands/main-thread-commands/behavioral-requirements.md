
- **thread-confined-access**: The adaptor MUST be confined to a single,
  serialized execution context; every stored value read or write and every
  method body MUST execute on that same confined context.
- **one-registry-per-adaptor-no-default**: Constructing the adaptor MUST
  take the shared command registry as a required parameter with no default
  value, so a caller cannot receive a private registry silently and have
  every extension command vanish from the app's own command palette.
- **ownership-record-not-a-dispatch-table**: The ownership record MUST
  record only the ids this specific adaptor instance has registered (each
  entry holding the registered callback and the registration token for
  that registration); dispatch MUST always go through the shared
  registry, never through the ownership record directly.
- **register-raises-on-torn-down-adaptor**: Registering a command MUST be
  built with the raised-exception teardown response, so a call after the
  adaptor's owner has been deallocated raises an exception rather than
  resolving or answering "undefined."
- **register-requires-string-command-id**: Handling a register-command
  call MUST raise `"registerCommand requires a string command id."` and
  return without registering anything when the first argument is missing
  or is not a string.
- **register-requires-callback-argument**: Handling a register-command
  call MUST raise `"registerCommand requires a callback function."` and
  return without registering anything when no second argument was
  supplied.
- **register-requires-function-callback**: Handling a register-command
  call MUST test the second argument against the calling context's own
  function type, and when that test fails (including when that type check
  is unavailable) MUST raise `"registerCommand's callback must be a
  function."` and return without registering anything.
- **register-rejects-duplicate-within-adaptor**: Handling a
  register-command call MUST raise `"command '<id>' already exists"` and
  return without registering anything when the ownership record already
  holds an entry for that id; a duplicate the app or a different
  extension's adaptor instance owns is out of scope for this check and
  MUST fall through to the shared registry's own replace-and-warn (or
  built-in-refusal) behavior instead.
- **register-requires-dispatchable-context**: Handling a register-command
  call MUST raise the shared dispatch-unavailable message and return
  without registering anything when the active context cannot dispatch,
  refusing before a disposable is ever handed back for a command that
  could never be invoked.
- **register-normalizes-nullish-this-arg**: Handling a register-command
  call MUST treat a third argument that is absent, "undefined," or "null"
  as "no receiver" (binding nothing), and MUST bind any other third-
  argument value (including a falsy value such as `false` or `0`) as the
  receiver unchanged.
- **register-marks-registration-extension-contributed**: Handling a
  register-command call MUST mark every command it registers as
  extension-contributed, so the shared registry's built-in-versus-
  extension collision refusal applies to it.
- **register-uses-the-command-id-as-its-title**: Handling a
  register-command call MUST construct the registered command with its
  title equal to the raw id, giving the command palette no separate
  human-readable title or category for an extension-registered command.
- **register-returns-a-disposable-that-unregisters-this-registration**: On
  success, handling a register-command call MUST return a disposable
  whose dispose operation removes exactly the registration just made and
  no other.
- **register-records-ownership-before-returning**: Handling a
  register-command call MUST store the callback and token in the
  ownership record before constructing and returning the disposable.
- **dispatch-consumes-the-caller-flag-exactly-once**: The dispatch a
  registered command runs through MUST consume the caller flag exactly
  once per dispatch, before invoking the callback, reading and resetting
  the flag to false in the same step.
- **dispatch-has-caller-is-static-not-instance**: The caller flag MUST be
  shared across every adaptor instance, not held per instance, because the
  flag describes one dispatch (whether an awaiting extension caller is
  waiting on it) rather than a fact about which adaptor instance is
  running it — an extension awaiting a command a *different* extension's
  adaptor registered must still be recognized as a caller by that other
  adaptor's dispatch.
- **dispatch-has-caller-restored-after-a-caller-dispatch**: Marking a
  dispatch as having a caller MUST save the previous value of the caller
  flag, set it to true, run the dispatch, and restore the previous value
  afterward regardless of outcome — so a nested execute-command call made
  from inside a command callback that itself has no caller is not left
  permanently marked as having one.
- **invoke-returns-the-callback-value-on-success**: Invoking a registered
  callback MUST, when the call answers with a returned value, return that
  value unchanged.
- **invoke-observes-async-rejection-only-when-caller-less**: Invoking a
  registered callback MUST attach a rejection observer to a returned
  thenable value only when there is no caller; when there is a caller, it
  MUST attach nothing, leaving the extension's own await/catch as the sole
  observer of that rejection.
- **invoke-logs-a-caller-less-async-rejection**: The rejection handler
  attached when there is no caller MUST log, at error level, the command
  id and the rejection reason's string form (or a placeholder when that
  string form is unavailable).
- **invoke-returns-callback-failure-on-throw**: Invoking a registered
  callback MUST, when the call answers with a thrown value, return a
  callback-failure result wrapping it, and MUST NOT let the exception
  propagate as a host error or reach the host's own pending-exception
  state.
- **invoke-logs-a-caller-less-throw**: Invoking a registered callback MUST
  log, at error level, the command id and the thrown value's string form
  (or a placeholder) only when there is no caller; when there is a caller
  it MUST NOT log, leaving the rejection this throw becomes (via
  execute-command) as the extension's own responsibility.
- **invoke-returns-dispatch-unavailable-never-nil**: Invoking a registered
  callback MUST, when the call answers "unavailable," return a
  dispatch-unavailable result and MUST NOT answer nothing, because
  answering nothing here would resolve an execute-command promise with
  "undefined," which is what a void command that ran successfully also
  answers.
- **invoke-logs-dispatch-unavailable-unconditionally**: Invoking a
  registered callback MUST log, at error level, the command id whenever
  the call answers "unavailable," regardless of whether there is a caller,
  because that case is a host fault rather than an extension's, so an
  operator must be able to find it in the log even when the extension
  awaited nothing.
- **execute-rejects-on-torn-down-adaptor**: Executing a command MUST be
  built with the rejected-promise teardown response, so a call after the
  adaptor's owner has been deallocated rejects the returned promise rather
  than raising synchronously or answering "undefined."
- **execute-requires-string-command-id**: Handling an execute-command call
  MUST answer a promise rejected with `"executeCommand requires a string
  command id."` when the first argument is missing or is not a string.
- **execute-forwards-remaining-arguments-untouched**: Handling an
  execute-command call MUST pass every argument after the command id, as
  the same values the caller supplied and with no conversion, to the
  shared registry's execute operation.
- **execute-marks-its-dispatch-as-having-a-caller**: Handling an
  execute-command call MUST wrap its call to the shared registry's execute
  operation in the caller-marking helper, marking that one dispatch as
  having a caller for the invoke operation to read.
- **execute-rejects-on-dispatch-unavailable**: Handling an execute-command
  call MUST answer a promise rejected with the shared dispatch-unavailable
  message when the registry's execute operation answers "unavailable,"
  and MUST NOT resolve with "undefined" in that case.
- **execute-rejects-with-the-extensions-own-exception**: Handling an
  execute-command call MUST answer a promise rejected with the
  callback-failure's own reason, unchanged, when the registry's execute
  operation answers a callback failure, preserving the extension's own
  error subclass and stack rather than paraphrasing it.
- **execute-settles-a-thenable-result**: Handling an execute-command call
  MUST settle its returned promise with the script value the registry's
  execute operation answers, so an async command callback's own promise
  (or a plain returned value) settles the extension's await with the
  value the command actually produced.
- **execute-resolves-a-native-result**: Handling an execute-command call
  MUST resolve its returned promise with the result, when the registry's
  execute operation answers any value that is neither "unavailable," a
  callback failure, nor a script value (an app-registered command's
  native return value, bridged into the script engine).
- **execute-translates-registry-errors-verbatim**: Handling an
  execute-command call MUST answer a promise rejected with the registry
  error's own wording (`"No command is registered with id '<id>'"` for an
  unknown command, `"Command '<id>' is registered but currently
  disabled"` for a disabled command) rather than paraphrasing it, when the
  registry's execute operation throws one of those two named errors.
- **execute-rejects-on-any-other-thrown-error**: Handling an
  execute-command call MUST answer a promise rejected with that error's
  own description, for any error the registry's execute operation throws
  that is not one of those two named errors.
- **get-commands-rejects-on-torn-down-adaptor**: Getting the list of
  commands MUST be built with the rejected-promise teardown response.
- **get-commands-defaults-to-including-every-id**: Handling a
  get-commands call MUST treat a first argument that is absent,
  "undefined," false, or any other falsy value as "do not filter,"
  answering with every id the shared registry knows.
- **get-commands-filters-underscore-prefixed-ids-on-true**: Handling a
  get-commands call MUST, when the first argument's boolean value is
  true, exclude every id that starts with an underscore from the result.
- **get-commands-never-rejects-for-its-own-reason**: Handling a
  get-commands call MUST always resolve its returned promise and MUST NOT
  reject it for its own reasons, because reading the registry's known
  commands cannot fail; the only rejection this member can produce is the
  teardown rejection from **get-commands-rejects-on-torn-down-adaptor**.
- **get-commands-preserves-registration-order**: Handling a get-commands
  call MUST answer the ids in the registry's own order, without
  re-sorting them.
- **dispose-unregisters-every-owned-command**: Tearing the adaptor down
  MUST unregister every entry currently in the ownership record, and MUST
  leave the ownership record empty when it returns.
- **unregister-is-guarded-by-both-ownership-and-token**: Unregistering an
  id and token MUST remove the registration named by both from the
  ownership record and the shared registry only when the ownership record
  holds an entry for that id whose stored token equals the given token;
  when either check fails it MUST do nothing.
- **disposable-is-idempotent**: The disposable returned when registering a
  command MUST unregister its registration on its first dispose call and
  MUST do nothing on every subsequent dispose call on the same disposable,
  per the underlying disposable-building operation's own single-call
  guarantee.
- **disposable-captures-a-fixed-token**: The token a disposable
  unregisters MUST be the one captured for it at the time the disposable
  was built, not re-read from the ownership record at dispose time, so a
  disposable minted before a dispose-and-re-register cycle finds its
  captured token no longer matches the live registration and becomes a
  no-op rather than unregistering the adaptor's own fresh registration of
  the same id.
- **teardown-does-not-capture-self**: The dispatch a registered command
  runs through MUST capture no reference to the adaptor instance, reading
  only shared state and the receiver/callback values captured at
  registration time, so the adaptor is not kept alive by the registry's
  own retain graph.
- **logging-conformance**: The adaptor MUST participate in the host's
  logging convention, exposing a logger built from its own name.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

