
**Decision**: presentation is always a sheet, never an application-modal alert.
**Rationale**: stated in the type's own doc comment — this is an `LSUIElement` menu-bar app for which `NSAlert.runModal()` would activate the app and make its window key, seizing the screen from whoever is typing, and would additionally block the main thread until dismissed, risking a UI wedge if no window happens to be available.
**Approved**: pending

**Decision**: with no window anywhere in the app, the message is dropped (logged, resolved `nil`) rather than shown by any other means.
**Rationale**: stated in the type's own doc comment — there is no surface a sheet can attach to that does not seize the screen, so the message is logged and resolved the same as a user dismissal, a state `vscode.d.ts` already requires every caller to handle; losing one extension's message is judged the smaller harm.
**Approved**: pending

**Decision**: `window` is an injected closure with no default value.
**Rationale**: stated in `init(window:)`'s own doc comment — the no-window fallback must be an explicit choice a caller made, not an incidental default the initializer picked, and not guessed at from `NSApplication.shared` or another ambient source.
**Approved**: pending

**Decision**: `buttonPlan(for:)` and `escapeKeyEquivalentPosition(in:)` are `internal`, not `private`.
**Rationale**: stated in both functions' own doc comments — `MainThreadWindowTests` calls each directly through `@testable import AgenticToolkitMacOS`, and tightening either to `private` compiles here but breaks that suite.
**Approved**: pending

**Decision**: Escape is assigned to the cancel-slot button only when the plan has more than one entry.
**Rationale**: stated in `escapeKeyEquivalentPosition(in:)`'s own doc comment — on a one-entry plan, the cancel slot is also the sole button, which `NSAlert` already gives Return by default; assigning Escape there would replace Return (and its default-button status) for no behavioral gain, since a one-entry plan only arises when every item was flagged and the sole button already is the close affordance.
**Approved**: pending

**Decision**: `closeAffordanceIndices`'s last-wins tie-break in the cancel slot is applied here, not re-derived here.
**Rationale**: the rule itself — the *last* flagged item's index wins the single cancel slot — is documented in full, with its upstream justification, in [ExtensionMessagePresenting](adtoolkit://cookbook/workspace/extensions/vscode-api/window/extension-message-presenting)'s Design Decisions; **button-plan-cancel-slot** in this recipe applies that same rule to this conformer's concrete AppKit button layout rather than restating the rationale.
**Approved**: pending

**Decision**: `presentedResponse(for:)` bridges `beginSheetModal(for:completionHandler:)` into `async` with `withCheckedContinuation`, unlike every other `beginSheetModal` site in this tier.
**Rationale**: stated in the source's own doc comment as a claim measured against the rest of the `macOS/` tier — every other `beginSheetModal` site (`ComposableTabsPaneViewController`, `AISettingsViewPanelController`, `ExtensionsSettingsPanelViewController`, `NotesFolderListViewController`, `NotesSplitViewController`) drives its completion handler directly, while this presenter must be `async` to satisfy `ExtensionMessagePresenting`; `withCheckedContinuation` itself is not unprecedented in the tier (`ExtensionHost.swift` uses one for a JS activation callback), only its pairing with `NSAlert`/`beginSheetModal` is.
**Approved**: pending

**Decision**: this recipe traces `presentMessage(_:)`, `sheetWindow()`, `presentedResponse(for:)`, `alertStyle(for:)`, and `anyVisibleWindow()` to the source only, with no given test exercising any of them directly.
**Rationale**: every case in `MainThreadWindowTests.swift` that exercises message presentation substitutes a `RecordingMessagePresenter` or `SuspendingMessagePresenter` test double for `NSAlertMessagePresenter` precisely to avoid putting a real sheet on screen during a test run; `buttonPlan(for:)` and `escapeKeyEquivalentPosition(in:)` were split out as `internal`, side-effect-free functions specifically so something about the button layout could still be pinned without running `beginSheetModal(for:completionHandler:)`.
**Approved**: pending

