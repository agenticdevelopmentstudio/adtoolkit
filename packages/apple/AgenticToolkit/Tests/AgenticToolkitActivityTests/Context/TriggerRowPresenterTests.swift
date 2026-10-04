import XCTest
@testable import AgenticToolkitActivity

final class TriggerRowPresenterTests: XCTestCase {

    // MARK: - state(for:in:)

    func testEmptyReplyProducesUnknownNotOff() {
        let row = TriggerRowPresenter.state(for: .appFocus, in: [])
        XCTAssertEqual(row.availability, .unknown)
        XCTAssertFalse(row.isControlEnabled)
    }

    func testKindMissingFromANonEmptyReplyIsAlsoUnknown() {
        // Defensive: the daemon always answers with all eight kinds, but a
        // row's presenter must not silently treat "not present" as "off"
        // even when some other kind IS present.
        let states = [TriggerState(kind: .power, isEnabled: true, permission: .none,
                                    permissionState: .granted, isRunning: true)]
        let row = TriggerRowPresenter.state(for: .location, in: states)
        XCTAssertEqual(row.availability, .unknown)
    }

    func testKnownDisabledStateProjectsOff() {
        let states = [TriggerState(kind: .network, isEnabled: false, permission: .none,
                                    permissionState: .granted, isRunning: false)]
        let row = TriggerRowPresenter.state(for: .network, in: states)
        XCTAssertEqual(row.availability, .off)
        XCTAssertTrue(row.isControlEnabled)
        XCTAssertFalse(row.isBlocked)
    }

    func testEnabledAndRunningIsOnAndNotBlocked() {
        let states = [TriggerState(kind: .session, isEnabled: true, permission: .none,
                                    permissionState: .granted, isRunning: true)]
        let row = TriggerRowPresenter.state(for: .session, in: states)
        XCTAssertEqual(row.availability, .on)
        XCTAssertFalse(row.isBlocked)
    }

    func testEnabledButNotRunningIsOnAndBlocked() {
        let states = [TriggerState(kind: .location, isEnabled: true, permission: .location,
                                    permissionState: .denied, isRunning: false)]
        let row = TriggerRowPresenter.state(for: .location, in: states)
        XCTAssertEqual(row.availability, .on)
        XCTAssertTrue(row.isBlocked)
        XCTAssertEqual(row.permission, .location)
        XCTAssertEqual(row.permissionState, .denied)
    }

    /// `isEnabled == false` with `isRunning == true` is documented reachable
    /// on `TriggerState` (a settings-read failure fails `isEnabled` closed
    /// without stopping an already-running trigger). Rendering this as plain
    /// `.off` would show an unchecked box for a trigger that is, at that
    /// moment, still emitting events.
    func testDisabledButStillRunningIsOffButRunningNotPlainOff() {
        let states = [TriggerState(kind: .power, isEnabled: false, permission: .none,
                                    permissionState: .granted, isRunning: true)]
        let row = TriggerRowPresenter.state(for: .power, in: states)
        XCTAssertEqual(row.availability, .offButRunning)
        XCTAssertTrue(row.isControlEnabled)
        XCTAssertEqual(row.isChecked, true)
    }

    // MARK: - isChecked

    /// The checkbox glyph must never collapse "unknown" into "unchecked" —
    /// that is exactly the claim `.off` makes, and `.unknown` does not know
    /// that to be true.
    func testIsCheckedNeverCollapsesUnknownIntoUnchecked() {
        XCTAssertNil(TriggerRowState.unknown(.window).isChecked)
    }

    func testIsCheckedReflectsOffButRunningAsChecked() {
        let row = TriggerRowState(kind: .window, availability: .offButRunning, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertEqual(row.isChecked, true)
    }

    // MARK: - intent(forClickOn:)

    /// The regression that made the whole opt-in surface inert. The panel read
    /// a click's meaning from `NSButton.state` *after* AppKit advanced it, and
    /// a three-state checkbox goes off → mixed → on → off — so clicking an
    /// unchecked row landed on `.mixed`, was read as "not on", and asked the
    /// daemon for `enabled: false`. Verified live: two different triggers each
    /// persisted `0` when clicked from unchecked. Intent must come from the
    /// state the panel rendered, where "unchecked" can only mean one thing.
    func testClickingAnOffRowAsksForItToBeTurnedOn() {
        let row = TriggerRowState(kind: .network, availability: .off, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertTrue(TriggerRowPresenter.intent(forClickOn: row))
    }

    func testClickingAnOnRowAsksForItToBeTurnedOff() {
        let row = TriggerRowState(kind: .network, availability: .on, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertFalse(TriggerRowPresenter.intent(forClickOn: row))
    }

    /// A row the daemon has not answered for renders as a half-tick; if it is
    /// somehow clicked anyway, the click reads as "turn it on" rather than
    /// sending a spurious disable for a trigger whose state nobody knows.
    func testClickingAnUnknownRowAsksForItToBeTurnedOn() {
        XCTAssertTrue(TriggerRowPresenter.intent(forClickOn: .unknown(.location)))
    }

    /// `.offButRunning` draws checked, so a click on it reads as "turn it
    /// off" — matching the box the user saw, not the setting behind it (which
    /// already says off).
    func testClickingAnOffButRunningRowAsksForItToBeTurnedOff() {
        let row = TriggerRowState(kind: .input, availability: .offButRunning, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertFalse(TriggerRowPresenter.intent(forClickOn: row))
    }

    /// Pins glyph and intent together with values written out by hand, so a
    /// change to either function has to disagree with this table rather than
    /// with the other function's current behaviour. Asserting
    /// `intent == (isChecked != true)` instead would restate the
    /// implementation and pass no matter what both of them did.
    func testEveryAvailabilityPairsAGlyphWithTheOppositeIntent() {
        let expected: [(TriggerRowState.Availability, Bool?, Bool)] = [
            (.unknown, nil, true),
            (.off, false, true),
            (.offButRunning, true, false),
            (.on, true, false),
        ]
        for (availability, glyph, intent) in expected {
            let row = TriggerRowState(kind: .power, availability: availability, permission: .none,
                                       permissionState: .granted, isBlocked: false)
            XCTAssertEqual(row.isChecked, glyph, "glyph for \(availability)")
            XCTAssertEqual(TriggerRowPresenter.intent(forClickOn: row), intent,
                           "intent for \(availability)")
        }
    }

    // MARK: - explanation(for:)

    func testUnknownRowExplanationSaysWaitingForTheDaemon() throws {
        let explanation = try XCTUnwrap(TriggerRowPresenter.explanation(for: .unknown(.window)))
        XCTAssertTrue(explanation.contains("Waiting for"), "got \(explanation)")
    }

    func testOffRowHasNoExplanation() {
        let row = TriggerRowState(kind: .window, availability: .off, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertNil(TriggerRowPresenter.explanation(for: row))
    }

    func testOffButRunningExplanationSaysItIsStillRecording() throws {
        let row = TriggerRowState(kind: .window, availability: .offButRunning, permission: .none,
                                   permissionState: .granted, isBlocked: false)
        let explanation = try XCTUnwrap(TriggerRowPresenter.explanation(for: row))
        XCTAssertTrue(explanation.contains("recording"), "got \(explanation)")
    }

    func testOnAndRunningRowHasNoExplanation() {
        let row = TriggerRowState(kind: .appFocus, availability: .on, permission: .accessibility,
                                   permissionState: .granted, isBlocked: false)
        XCTAssertNil(TriggerRowPresenter.explanation(for: row))
    }

    func testOnAndBlockedRowNamesThePermissionAndItsState() throws {
        let row = TriggerRowState(kind: .appFocus, availability: .on, permission: .accessibility,
                                   permissionState: .denied, isBlocked: true)
        let explanation = try XCTUnwrap(TriggerRowPresenter.explanation(for: row))
        XCTAssertTrue(explanation.contains("Accessibility"), "got \(explanation)")
        XCTAssertTrue(explanation.contains("denied"), "got \(explanation)")
    }

    /// `permission == .none` is real for five of the eight kinds
    /// (`session`/`power`/`network`/`input`/`app_lifecycle`); a blocked row
    /// for one of them must not read "Waiting on no permission"
    /// (`title(for: .none)` is "no"). `window` is *not* one of them — it
    /// requires `.accessibility`, same as `app_focus` — so this uses a kind
    /// whose permission really is `.none`.
    func testOnAndBlockedRowWithNoPermissionNeededDoesNotMentionPermission() throws {
        let row = TriggerRowState(kind: .session, availability: .on, permission: .none,
                                   permissionState: .granted, isBlocked: true)
        let explanation = try XCTUnwrap(TriggerRowPresenter.explanation(for: row))
        XCTAssertFalse(explanation.contains("permission"), "got \(explanation)")
    }

    // MARK: - The settling copy

    /// The "it should settle shortly" copy is a promise about
    /// `ContextRefresh.interval` — the period of the only loop that re-checks
    /// a trigger's gates. Written out as a literal it went stale silently the
    /// moment the schedule was retuned, so both sentences are built from the
    /// constant and are checked here against it, never against "30".
    func testTheSettlingCopyQuotesTheActualRefreshInterval() throws {
        let seconds = Int(ContextRefresh.interval.components.seconds)

        let stillRunning = TriggerRowState(kind: .network, availability: .offButRunning,
                                           permission: .none, permissionState: .granted,
                                           isBlocked: false)
        let stopping = try XCTUnwrap(TriggerRowPresenter.explanation(for: stillRunning))
        XCTAssertTrue(stopping.contains(ContextRefresh.phrase), "got \(stopping)")
        XCTAssertTrue(stopping.contains("\(seconds)"), "got \(stopping)")

        let blocked = TriggerRowState(kind: .session, availability: .on, permission: .none,
                                      permissionState: .granted, isBlocked: true)
        let starting = try XCTUnwrap(TriggerRowPresenter.explanation(for: blocked))
        XCTAssertTrue(starting.contains(ContextRefresh.phrase), "got \(starting)")
        XCTAssertTrue(starting.contains("\(seconds)"), "got \(starting)")
    }

    func testAnIntervalUnderAMinuteIsPhrasedInSeconds() {
        XCTAssertEqual(ContextRefresh.phrase,
                       "about \(Int(ContextRefresh.interval.components.seconds)) seconds",
                       "today's interval is under a minute")
    }

    // MARK: - advice(for:permission:)

    func testAGrantedRequestSaysSoAndSendsNobodyToSystemSettings() {
        let advice = TriggerRowPresenter.advice(for: .granted, permission: .accessibility)
        XCTAssertTrue(advice.message.contains("Accessibility"), "got \(advice.message)")
        XCTAssertFalse(advice.opensSystemSettings)
    }

    /// Denied and undetermined are the same advice on purpose: macOS shows its
    /// prompt once per executable, ever, so "nothing appeared" and "the user
    /// said no" both leave System Settings as the only remaining route.
    func testARefusedRequestOpensSystemSettingsAndNamesTheOlyloEntry() {
        for result in [PermissionRequestResult.denied, .undetermined] {
            let advice = TriggerRowPresenter.advice(for: result, permission: .location)
            XCTAssertTrue(advice.opensSystemSettings, "\(result) must offer the pane")
            XCTAssertTrue(advice.message.contains("Location"), "got \(advice.message)")
            XCTAssertTrue(advice.message.contains("Olylo"), "got \(advice.message)")
        }
    }

    /// The one instruction this surface must never give: there is no `olylod`
    /// row in System Settings to switch on. The daemon ships inside the app
    /// bundle and macOS authorizes both under the app's identity, so naming
    /// olylod sends the owner hunting for a row that does not exist.
    func testNoAdviceTellsTheOwnerToLookForAnOlylodEntry() {
        let results: [PermissionRequestResult] =
            [.granted, .denied, .undetermined, .notNeeded, .unavailable]
        for result in results {
            for permission in ContextPermission.allCases {
                let message = TriggerRowPresenter.advice(for: result, permission: permission).message
                XCTAssertFalse(message.contains("switch on olylod"), "got \(message)")
                XCTAssertFalse(message.contains("find olylod"), "got \(message)")
            }
        }
    }

    func testARequestNobodyNeededExplainsWhatToDoFirstAndOpensNothing() {
        let advice = TriggerRowPresenter.advice(for: .notNeeded, permission: .location)
        XCTAssertTrue(advice.message.contains("Switch on a trigger"), "got \(advice.message)")
        XCTAssertFalse(advice.opensSystemSettings)
    }

    /// A daemon that never answered must not be reported as a refusal: nothing
    /// was asked for, so there is nothing in System Settings to fix.
    func testAnUnavailableDaemonIsNotReportedAsARefusal() {
        let advice = TriggerRowPresenter.advice(for: .unavailable, permission: .accessibility)
        XCTAssertFalse(advice.opensSystemSettings)
        XCTAssertTrue(advice.message.contains("olylod isn't responding"), "got \(advice.message)")
    }

    // MARK: - title(for:)

    func testEveryKindHasADistinctNonEmptyTitle() {
        let titles = ContextEventKind.allCases.map(TriggerRowPresenter.title(for:))
        XCTAssertTrue(titles.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(titles).count, titles.count, "titles must be distinct: \(titles)")
    }
}
