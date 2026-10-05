
- **thread-confined-access**: The adaptor MUST be confined to a single,
  serialized execution context; every stored value read and write and every
  method body MUST execute on that same confined context.
- **init-requires-every-collaborator-with-no-default**: Constructing the
  adaptor MUST take the presenter, the not-implemented ledger, the extension
  identifier, the extension directory, and the workspace roots provider as
  five required parameters with no default value.
- **workspace-roots-are-read-fresh-not-snapshotted**: Resolving local
  resource roots and building a create-webview-panel request MUST read the
  workspace roots provider's own workspace-root locations at call time, MUST
  NOT cache them at construction, so a workspace folder opened after
  construction is reflected in the very next `createWebviewPanel` call's
  resolved roots.
- **panel-record-is-the-sole-strong-reference**: The panel record MUST be
  the only strong reference this adaptor (or the script objects it builds)
  holds to a panel model; forgetting a panel (removing its entry) MUST be
  what makes every callback captured by that model's script objects inert.
- **create-panel-raises-on-torn-down-adaptor**: `createWebviewPanel` MUST be
  built with the raised-exception teardown response, and a call after the
  adaptor has been torn down MUST raise `"vscode.window.createWebviewPanel
  is unavailable: this extension's host has been torn down."` rather than
  returning `undefined` or a non-functional panel object.
- **create-panel-requires-string-view-type**: Handling a create-webview-panel
  call MUST raise `"vscode.window.createWebviewPanel's first argument must
  be a view type string."` and present nothing when the first argument is
  missing or not a string.
- **create-panel-requires-string-title**: Handling a create-webview-panel
  call MUST raise `"vscode.window.createWebviewPanel's second argument must
  be a title string."` and present nothing when the second argument is
  missing or not a string.
- **create-panel-parses-preserve-focus-from-third-argument**: Handling a
  create-webview-panel call MUST derive `preserveFocus` from the third
  argument (or treat it as absent when no third argument was supplied),
  reading only that value's `preserveFocus` field and ignoring any
  `ViewColumn` the third argument might otherwise represent — this app's
  panes are a user-arranged tree with no numbered column for a `ViewColumn`
  to select.
- **create-panel-parses-options-from-fourth-argument**: Handling a
  create-webview-panel call MUST derive `WebviewPanelOptions` from the
  fourth argument (or treat it as absent when no fourth argument was
  supplied).
- **create-panel-resolves-roots-before-presenting**: Handling a
  create-webview-panel call MUST compute `localResourceRoots` by resolving
  local resource roots for the given options and include the
  already-resolved list in the request handed to the presenter, so the
  presenter never has to know the extension's install directory or the
  open workspace folders itself.
- **create-panel-raises-when-no-window-is-open**: Handling a
  create-webview-panel call MUST log, at error level, that the extension
  asked for a panel with no window to put it in, and MUST raise
  `"vscode.window.createWebviewPanel could not open a panel for view type
  '<viewType>': this app's windows belong to open projects, and none is
  open."` when the presenter answers no request.
- **create-panel-closes-and-raises-when-the-panel-object-cannot-be-built**:
  when building the panel object fails after a presenter has already put a
  panel on screen, handling a create-webview-panel call MUST dispose the
  just-presented panel, MUST log the failure at error level, and MUST raise
  `"vscode.window.createWebviewPanel could not build a panel object for
  view type '<viewType>'."`, leaving no pane the extension can never
  address.
- **create-panel-adopts-only-on-full-success**: Handling a
  create-webview-panel call MUST adopt the model only after both presenting
  and building the panel object succeed, and MUST return the built panel
  object as the member's result.
- **panel-model-events-use-immediate-delivery**: Every event emitter a panel
  model constructs (for `onDidReceiveMessage`, `onDidDispose`, and the
  shared view-state-change emitter behind `onDidChangeViewState`/
  `onDidChangeVisibility`) MUST be built for synchronous, same-turn
  delivery, so a page's `postMessage` reaches the extension's
  `onDidReceiveMessage` listener in the same turn it was sent.
- **view-state-changes-are-real-but-never-fired**: The shared
  view-state-change emitter MUST remain a genuinely subscribable emitter (an
  extension's `Disposable` from subscribing to it MUST be valid and
  disposable), but nothing in this adaptor MUST ever fire it, because panes
  here do not yet report view-state transitions.
- **wire-captures-the-panel-id-by-value**: Wiring a panel's `onDidDispose`
  callback MUST capture the panel id by copy at wiring time, MUST NOT read
  the model's own panel id after forgetting has removed the model from the
  panel record.
- **disposal-fires-before-forgetting**: The `onDidDispose` callback that
  wiring installs MUST mark the model disposed and fire its disposal event
  before forgetting the panel, so every listener the extension registered
  on `onDidDispose` is still present in the model's disposal registrations
  at the moment it fires.
- **abandon-is-only-for-an-undelivered-hand-over**: Abandoning a model MUST
  happen only when a hand-over (`restore` or `resolveWebviewView`) adopted a
  model and then could not deliver an object to the extension at all (a
  dispatch result of "unavailable"); it MUST null the model's
  `onDidDispose` and `onDidReceiveMessage` callbacks and forget the panel,
  and MUST NOT happen for a hand-over whose extension received the object
  and then threw — a throwing extension MUST keep its panel.
- **refused-hand-over-is-logged-not-silent**: Logging a refused hand-over
  MUST log, at notice level, that the panel or view named by the identifier
  was closed before the extension could fill it and is not handed over,
  whenever `restore` or `resolveWebviewView` refuses an already-disposed
  panel.
- **register-serializer-raises-on-torn-down-adaptor**:
  `registerWebviewPanelSerializer` MUST be built with the raised-exception
  teardown response, raising `"vscode.window.registerWebviewPanelSerializer
  is unavailable: this extension's host has been torn down."` after the
  adaptor is torn down.
- **register-serializer-requires-string-view-type**: Handling a
  register-webview-panel-serializer call MUST raise
  `"vscode.window.registerWebviewPanelSerializer's first argument must be a
  view type string."` when the first argument is missing or not a string.
- **register-serializer-requires-a-callable-deserialize-method**: Handling a
  register-webview-panel-serializer call MUST test the second argument for
  being an object with a callable `deserializeWebviewPanel` property, and
  MUST raise `"vscode.window.registerWebviewPanelSerializer's second
  argument must be an object with a deserializeWebviewPanel(panel, state)
  method."` when either check fails — checking the object alone (being an
  object, true of `{}`) would let a mistyped method name register
  successfully and silently restore nothing, months later.
- **register-serializer-last-registration-wins-and-is-logged**: Handling a
  register-webview-panel-serializer call MUST replace any existing
  registration for the view type with the new one (last write wins,
  matching upstream's own behavior) and MUST log the replacement at error
  level when one already existed.
- **register-serializer-returns-a-token-guarded-disposable**: Handling a
  register-webview-panel-serializer call MUST mint a fresh registration
  token and return a `Disposable` whose `dispose()` removes the
  registration only when the live entry's token still equals the token
  captured at registration time.
- **has-serializer-false-when-disposed-or-missing**: Checking whether a
  serializer is registered MUST answer `false` when the adaptor is torn
  down, and MUST otherwise answer whether a registration exists for that
  view type.
- **restore-refuses-when-disposed-or-unregistered**: `restore` MUST return
  `false` immediately, with no side effect, when the adaptor is torn down
  or no serializer is registered for the view type.
- **restore-refuses-an-already-closed-panel**: `restore` MUST return
  `false` and MUST log a refused hand-over — MUST NOT adopt the model, MUST
  NOT wire `onDidDispose`/`onDidReceiveMessage` on the panel, MUST NOT call
  `deserializeWebviewPanel` — when the handed-over panel is already
  disposed at the moment of the call.
- **restore-refuses-an-uncallable-deserializer**: `restore` MUST log at
  error level and return `false` when the registered serializer has no
  callable `deserializeWebviewPanel` at call time.
- **restore-closes-nothing-when-the-panel-object-cannot-be-built**:
  `restore` MUST log at error level and return `false`, leaving the
  handed-over panel blank (and MUST NOT dispose it), when building a panel
  object for the restored panel fails.
- **restore-adopts-before-calling-deserialize**: `restore` MUST adopt the
  model before invoking `deserializeWebviewPanel`, so the panel is already
  wired for messages and disposal by the time the extension's own callback
  runs.
- **restore-parses-saved-state-as-json-or-undefined**: Parsing the restored
  state value MUST parse a non-absent saved state string as JSON and pass
  the decoded value to `deserializeWebviewPanel`, and MUST pass `undefined`
  — never JavaScript `null` — when the saved state is absent, because an
  extension's `state ?? defaults` and `if (state === undefined)` read the
  two differently.
- **restore-returns-true-on-successful-deserialize**: `restore` MUST return
  `true` when dispatching `deserializeWebviewPanel` answers "returned".
- **restore-keeps-the-panel-adopted-when-deserialize-throws**: `restore`
  MUST log the exception at error level and return `false`, but MUST NOT
  abandon the model — it MUST stay adopted — when dispatching
  `deserializeWebviewPanel` answers "threw".
- **restore-abandons-only-on-dispatch-unavailable**: `restore` MUST abandon
  the model, log at error level, and return `false` when dispatching
  `deserializeWebviewPanel` answers "unavailable".
- **register-view-provider-mirrors-the-serializer-contract**: Handling a
  register-webview-view-provider call MUST apply the same torn-down check,
  string-view-id check, and object-with-callable-`resolveWebviewView`-method
  check that handling a register-webview-panel-serializer call applies to
  view types and `deserializeWebviewPanel`, with the corresponding messages
  naming `vscode.window.registerWebviewViewProvider`, a view id string, and
  a `resolveWebviewView(webviewView, context, token)` method.
- **register-view-provider-drops-the-retain-context-hint-silently**:
  Handling a register-webview-view-provider call MUST read and discard the
  third argument's `webviewOptions.retainContextWhenHidden` field without
  recording a not-implemented-ledger row, because every pane here already
  retains its view regardless of front-most state, so a ledger row would
  report a limitation that does not exist.
- **register-view-provider-does-not-throw-on-duplicate**: Handling a
  register-webview-view-provider call MUST NOT raise or refuse a second
  registration for a view id already registered; it MUST log the
  replacement at error level and let the later registration win,
  deliberately diverging from upstream VS Code's throw — the "second"
  registration here is typically a post-reload registration, and honoring
  the app's earlier registration over the extension's would wire a live
  pane to a dead script context.
- **has-view-provider-false-when-disposed-or-missing**: Checking whether a
  view provider is registered MUST answer `false` when the adaptor is torn
  down, and MUST otherwise answer whether a registration exists for that
  view id.
- **resolve-view-refuses-when-disposed-or-unregistered**:
  `resolveWebviewView` MUST return `false` immediately when the adaptor is
  torn down or no provider is registered for the view id.
- **resolve-view-refuses-an-already-closed-panel**: `resolveWebviewView`
  MUST refuse (return `false`, log a refused hand-over, adopt nothing) a
  panel whose disposal has already happened, mirroring
  **restore-refuses-an-already-closed-panel** exactly.
- **resolve-context-state-is-always-undefined-and-ledgered**: Building the
  resolve context value MUST build a `WebviewViewResolveContext` whose
  `state` field is always `undefined`, and MUST record a
  not-implemented-ledger row for `vscode.WebviewViewResolveContext.state`
  the first time it is read, because a contributed view's state does not
  persist across a quit the way a serializer-backed panel's does.
- **resolve-view-token-never-cancels**: Building the never-cancelled
  cancellation token MUST return a `CancellationToken` whose
  `isCancellationRequested` is always `false` and whose
  `onCancellationRequested` returns a real, never-fired `Disposable`; this
  degraded argument MUST NOT be recorded in the ledger, unlike a genuinely
  absent capability, because it is a real (if permanently unfired) token
  rather than a missing member.
- **resolve-view-returns-true-on-successful-resolve**: `resolveWebviewView`
  MUST return `true` when dispatching `resolveWebviewView` (the extension's
  own provider method) answers "returned", and MUST log-and-return-`false`
  without abandoning on "threw", matching `restore`'s throw handling.
- **resolve-view-abandons-only-on-dispatch-unavailable**:
  `resolveWebviewView` MUST abandon the model, log at error level, and
  return `false` when dispatching the provider's `resolveWebviewView`
  answers "unavailable".
- **boolean-field-requires-an-actual-boolean**: Reading a boolean field MUST
  answer absent for any value that is not a boolean (no truthy coercion of
  a number, string, or object).
- **is-truthy-flag-requires-boolean-true**: Reading a truthy flag MUST
  answer `true` only when the value is a boolean equal to `true`; every
  other value, including a truthy non-boolean, MUST answer `false`.
- **resource-roots-field-distinguishes-absent-from-empty**: Parsing the
  declared resource-roots field MUST answer absent when the value is
  missing, `undefined`, or `null` (letting the options resolver's own
  extension-directory-plus-workspace default apply), and MUST answer an
  empty list when the value is an explicit, empty array (renouncing every
  default root).
- **resource-roots-field-drops-unparseable-entries**: Parsing the declared
  resource-roots field MUST drop any array element that does not parse as
  a `Uri`, rather than substituting a default for the whole list, because a
  partially-unreadable declared list is still the extension's explicit
  declaration.
- **ledger-records-a-reach-only-when-truthy-or-non-empty**: Parsing options
  MUST record a `vscode.WebviewOptions.enableCommandUris` ledger row only
  when that field is present and truthy, and a
  `vscode.WebviewOptions.portMapping` row only when that field is a
  non-empty array; an explicit `false` or `[]` MUST record nothing, because
  a decline is not a reach for something missing.
- **panel-webview-getter-builds-a-fresh-object-every-access**: The panel
  object's `webview` readonly property MUST construct a new `Webview`
  script object on every access, MUST NOT cache one on the model, honoring
  the no-capture contract that nothing stores a script value or script
  execution context on the panel model.
- **panel-title-is-an-accessor-pair-over-the-panel**: The panel object's
  `title` accessor pair MUST read and write the panel's own title directly,
  with no local cache.
- **panel-options-getter-answers-fixed-values**: The panel object's
  `options` readonly property MUST always answer
  `{retainContextWhenHidden: true, enableFindWidget: false}`, regardless of
  what the extension requested at creation.
- **panel-icon-path-is-write-only-into-the-ledger**: The panel object's
  `iconPath` getter MUST always answer `undefined`/`null`; its setter MUST
  record a `vscode.WebviewPanel.iconPath` ledger row only when assigned a
  non-`undefined`, non-`null` value.
- **panel-view-column-is-always-undefined**: The panel object's
  `viewColumn` readonly property MUST always answer `undefined`, with no
  ledger row, since there is no numbered column for it to name.
- **panel-active-and-visible-mirror-is-disposed**: The panel object's
  `active` and `visible` readonly properties MUST both answer whether the
  panel is not disposed, an acknowledged approximation that never corrects
  itself while a panel is open, because `onDidChangeViewState` never fires.
- **panel-view-state-subscription-is-ledgered-every-call**: The panel
  object's `onDidChangeViewState` method MUST record a
  `vscode.WebviewPanel.onDidChangeViewState` ledger row on every call
  before subscribing the listener to the shared view-state-change emitter.
- **panel-reveal-reads-its-second-argument-as-preserve-focus**: The panel
  object's `reveal` method MUST read its second argument as
  `preserveFocus` (defaulting to `false`), MUST ignore its first argument
  (the dropped `ViewColumn`), and MUST reveal the panel with that value.
- **panel-dispose-delegates-to-the-underlying-panel**: The panel object's
  `dispose` method MUST dispose the underlying panel and rely on that
  call's own idempotence.
- **view-title-mirrors-the-panels-title**: The webview-view object's
  `title` accessor pair MUST read and write the panel's own title,
  answering the pane's current chrome name rather than `undefined`.
- **view-description-and-badge-are-write-only-into-the-ledger**: The
  webview-view object's `description` and `badge` accessor pairs MUST both
  have no-op getters (always `undefined`/`null`) and setters that record a
  `vscode.WebviewView.description` or `vscode.WebviewView.badge` ledger row
  only for a non-`undefined`, non-`null` assigned value.
- **view-has-no-dispose-method**: The webview-view object MUST NOT expose a
  `dispose` method, matching upstream's `WebviewView`, because a
  contributed view's lifetime belongs to its manifest-declared pane, not to
  the extension.
- **view-visible-mirrors-is-disposed**: The webview-view object's `visible`
  readonly property MUST answer whether the panel is not disposed.
- **view-visibility-subscription-is-ledgered-every-call**: The webview-view
  object's `onDidChangeVisibility` method MUST record a
  `vscode.WebviewView.onDidChangeVisibility` ledger row on every call
  before subscribing to the shared view-state-change emitter.
- **view-show-reads-its-first-argument-as-preserve-focus**: The
  webview-view object's `show` method MUST read its first argument as
  `preserveFocus` (there being no `ViewColumn` to occupy that position for
  a contributed view).
- **webview-html-accessor-round-trips-through-the-panel**: The webview
  object's `html` accessor pair MUST read and write the panel's own HTML
  directly; assigning it MUST reload the page (the panel's own
  responsibility, not this adaptor's).
- **webview-csp-source-is-scheme-and-panel-id**: The webview object's
  `cspSource` readonly property MUST answer `"<scheme>://<panelID>"` using
  the resource URL builder's own scheme.
- **webview-as-webview-uri-requires-a-uri-argument**: The webview object's
  `asWebviewUri` method MUST raise `"vscode.Webview.asWebviewUri needs a
  Uri."` when its argument is missing or does not parse as a `Uri`, and
  otherwise MUST build the result via the resource URL builder, with no
  containment check performed at build time.
- **webview-post-message-resolves-false-without-posting-when-disposed**:
  The webview object's `postMessage` method MUST resolve its returned
  promise with `false` — without posting to the panel at all — when the
  model is already gone or disposed.
- **webview-post-message-resolves-the-panels-own-boolean**: When not
  disposed, `postMessage` MUST post the message — converted to its native
  representation, substituting a null placeholder when the message itself
  is absent — to the panel, and MUST resolve the returned promise with
  that call's own boolean result.
- **webview-on-did-receive-message-wraps-the-messages-emitter**: The
  webview object's `onDidReceiveMessage` method MUST subscribe the given
  listener to the model's messages emitter, delivered via the same-turn
  immediate window per **panel-model-events-use-immediate-delivery**.
- **webview-options-getter-omits-undeclared-roots**: The webview object's
  `options` getter MUST include `localResourceRoots` in its answer only
  when the panel's declared local resource roots are non-absent; it MUST
  omit the field entirely — not answer an empty array — when nothing was
  ever declared, matching `vscode.d.ts`'s optional-until-set semantics.
- **webview-options-setter-re-resolves-live-roots**: The webview object's
  `options` setter MUST re-parse the assigned value, MUST assign the
  result to the panel's own options, and MUST also recompute and assign the
  panel's live local resource roots by resolving them again, so writing
  `options` re-resolves the live roots against the same
  extension-directory-plus-workspace defaulting used at creation.
- **webview-local-resource-roots-getter-reads-live-roots**: The webview
  object's `localResourceRoots` getter MUST read the panel's own resolved,
  live roots directly, distinct from `options.localResourceRoots`'s
  declared-only view.
- **webview-local-resource-roots-setter-refuses-unparseable-whole-values**:
  The webview object's `localResourceRoots` setter MUST be a no-op —
  leaving the panel's live roots unchanged — when the assigned value cannot
  be parsed as a list of `Uri`s at all (including `undefined`/`null`), a
  deliberate divergence from the resource-roots field's per-element-drop
  behavior, reasoned around the asymmetric security consequence of
  silently revoking file access versus silently keeping it.
- **install-accessor-and-getter-delegate-to-main-thread-window**: Installing
  a property accessor or getter on a webview-related object MUST reuse the
  shared window adaptor's own property-installation helpers rather than
  duplicating property-descriptor logic.
- **dispose-is-idempotent**: Disposing the adaptor MUST be guarded against
  re-entry and MUST do nothing on a second call.
- **dispose-nulls-callbacks-before-disposing-each-panel**: Disposing the
  adaptor, for every live panel, MUST null `onDidDispose` and
  `onDidReceiveMessage` before disposing the panel and removing its
  listeners, so a mid-teardown callback cannot fire into a
  half-torn-down script context.
- **dispose-clears-every-registry**: Disposing the adaptor MUST clear the
  panel record, the serializer registry, and the view-provider registry
  entirely, so checking for a serializer or a view provider stops claiming
  any view type or view id afterward.
- **dispose-does-not-clear-on-removal-requested**: Disposing the adaptor
  MUST NOT touch a panel's own removal-requested callback (the app's own
  pane-placement callback, not this adaptor's), at the stated cost that a
  reconcile pass without a serializer hand-off loses the open pane, unlike
  VS Code's own reload-through-serializer behavior for that case.
- **logging-conformance**: The adaptor MUST participate in the host's
  logging convention, exposing a logger built from its own name.
- **restored-state-parse-failure-signal**: A saved state string that is
  absent, or that does not parse as JSON, MUST be handed to the extension's
  `deserializeWebviewPanel` as `undefined`, the same answer a panel that never
  called `setState` receives; a fragment such as a bare number MUST parse. The
  adaptor performs the parse itself rather than leaving it to the script so
  that a corrupt entry cannot leave an exception pending on the context. An
  unparseable saved state is not logged and not surfaced to the extension
  (see the pending design decision on corrupt saved state).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

