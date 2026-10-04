import XCTest
@testable import AgenticToolkitActivity

final class ContextEventSummaryTests: XCTestCase {

    func testKindDisplayNamesAreDerivedFromTheSchemaNames() {
        XCTAssertEqual(ContextEventKind.appFocus.displayName, "App Focus")
        XCTAssertEqual(ContextEventKind.window.displayName, "Window")
        for kind in ContextEventKind.allCases {
            XCTAssertFalse(kind.displayName.isEmpty, "\(kind) has no label")
            XCTAssertFalse(kind.displayName.contains("_"), "\(kind) label kept a raw underscore")
        }
    }

    func testEveryKindProducesANonEmptySubject() {
        let details: [ContextEventDetail] = [
            // Deliberately the *worst* case for each kind: every optional nil
            // and every identity string empty. A row with no identity still
            // has to name itself in the table.
            .appFocus(AppFocusDetail(bundleID: "", appName: "", pid: 0, executablePath: nil,
                                     windowID: nil, windowTitle: nil, documentPath: nil,
                                     documentSize: nil, documentModifiedAt: nil, documentType: nil)),
            .window(WindowDetail(change: .destroyed, bundleID: "", appName: "", pid: 0,
                                 windowID: 1, windowTitle: nil)),
            .network(NetworkDetail(interfaceType: .none, isSatisfied: false, ssid: nil,
                                   bssid: nil, isExpensive: nil, isConstrained: nil)),
            .location(LocationDetail(latitude: 0, longitude: 0, horizontalAccuracy: nil,
                                     altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)),
            .input(InputDetail(change: .sample, secondsSinceKey: nil, secondsSinceMouseMove: nil,
                               secondsSinceClick: nil, secondsSinceScroll: nil,
                               keyCountDelta: nil, mouseCountDelta: nil, intervalMs: nil)),
            .session(SessionDetail(change: .wake)),
            .power(PowerDetail(source: .ac, percent: nil, isCharging: nil)),
            .appLifecycle(AppLifecycleDetail(change: .launched, bundleID: "",
                                             appName: "", pid: 0))
        ]
        XCTAssertEqual(Set(details.map(\.kind)), Set(ContextEventKind.allCases),
                       "one fixture per kind — a count only proves there are eight of "
                       + "something, so a duplicated fixture would leave a kind untested "
                       + "here and still pass")

        for detail in details {
            XCTAssertFalse(detail.summary.subject.isEmpty, "\(detail.kind) rendered a blank subject")
        }
    }

    /// The two-part split only earns its keep if the two parts differ.
    ///
    /// Every kind whose subject can fall back to the bundle id also lists that
    /// bundle id among its detail parts, so an app with no name renders it
    /// twice: "com.example.headless — launched · com.example.headless · pid 7".
    /// The cases that avoided it each did so with their own ad-hoc guard,
    /// which is exactly how two of them came not to.
    func testNoKindRepeatsItsSubjectInTheDetail() {
        let namelessButIdentified: [ContextEventDetail] = [
            .appFocus(AppFocusDetail(bundleID: "com.example.headless", appName: "", pid: 7,
                                     executablePath: nil, windowID: nil, windowTitle: nil,
                                     documentPath: nil, documentSize: nil,
                                     documentModifiedAt: nil, documentType: nil)),
            .appLifecycle(AppLifecycleDetail(change: .launched, bundleID: "com.example.headless",
                                             appName: "", pid: 7)),
            .window(WindowDetail(change: .created, bundleID: "com.example.headless", appName: "",
                                 pid: 7, windowID: 3, windowTitle: nil)),
            .network(NetworkDetail(interfaceType: .wifi, isSatisfied: true, ssid: nil, bssid: nil,
                                   isExpensive: nil, isConstrained: nil))
        ]

        for detail in namelessButIdentified {
            let summary = detail.summary
            XCTAssertFalse(summary.detail.components(separatedBy: " · ").contains(summary.subject),
                           "\(detail.kind) printed its subject \"\(summary.subject)\" again in "
                           + "\"\(summary.detail)\"")
        }
    }

    func testAppFocusLeadsWithTheAppNameAndCarriesTheWindowTitle() {
        let summary = ContextEventDetail.appFocus(AppFocusDetail(
            bundleID: "com.googlecode.iterm2", appName: "iTerm2", pid: 1, executablePath: nil,
            windowID: nil, windowTitle: "tracking — zsh", documentPath: nil,
            documentSize: nil, documentModifiedAt: nil, documentType: nil)).summary

        XCTAssertEqual(summary.subject, "iTerm2")
        XCTAssertTrue(summary.detail.contains("tracking — zsh"), summary.detail)
        XCTAssertTrue(summary.detail.contains("com.googlecode.iterm2"), summary.detail)
    }

    func testAppFocusFallsBackToTheBundleIDWhenTheNameIsMissing() {
        let summary = ContextEventDetail.appFocus(AppFocusDetail(
            bundleID: "com.example.headless", appName: "", pid: 1, executablePath: nil,
            windowID: nil, windowTitle: nil, documentPath: nil,
            documentSize: nil, documentModifiedAt: nil, documentType: nil)).summary

        XCTAssertEqual(summary.subject, "com.example.headless")
    }

    /// The SSID is the label the user recognises, so it leads when present —
    /// and the interface type still shows up in the detail rather than being
    /// dropped.
    func testNetworkLeadsWithTheSSIDWhenThereIsOne() {
        let summary = ContextEventDetail.network(NetworkDetail(
            interfaceType: .ethernet, isSatisfied: true, ssid: "Studio",
            bssid: nil, isExpensive: nil, isConstrained: nil)).summary

        XCTAssertEqual(summary.subject, "Studio")
        XCTAssertTrue(summary.detail.contains("ethernet"), summary.detail)
        XCTAssertTrue(summary.detail.contains("reachable"), summary.detail)
    }

    func testNetworkFallsBackToTheInterfaceTypeWithoutAnSSID() {
        let summary = ContextEventDetail.network(NetworkDetail(
            interfaceType: .ethernet, isSatisfied: false, ssid: nil,
            bssid: nil, isExpensive: nil, isConstrained: nil)).summary

        XCTAssertEqual(summary.subject, "ethernet")
        XCTAssertEqual(summary.detail, "unreachable",
                       "the type is the subject here, so it is not repeated in the detail")
    }

    /// Coordinates are read next to raw database values, so they must not
    /// pick up the host locale's decimal separator or grouping.
    func testCoordinatesFormatIndependentlyOfLocale() {
        let summary = ContextEventDetail.location(LocationDetail(
            latitude: 37.331_23, longitude: -122.030_86, horizontalAccuracy: 35,
            altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)).summary

        XCTAssertEqual(summary.subject, "37.33123, -122.03086")
        XCTAssertEqual(summary.detail, "±35 m")
    }

    func testInputReportsCountsInTheSubjectAndGapsInTheDetail() {
        let summary = ContextEventDetail.input(InputDetail(
            change: .sample,
            secondsSinceKey: 0.42, secondsSinceMouseMove: 1.492_266_958,
            secondsSinceClick: nil, secondsSinceScroll: nil,
            keyCountDelta: 12, mouseCountDelta: 1_056, intervalMs: 30_000)).summary

        XCTAssertEqual(summary.subject, "12 keys, 1056 mouse")
        XCTAssertTrue(summary.detail.contains("move 1.5s ago"), summary.detail)
        XCTAssertTrue(summary.detail.contains("over 30000 ms"), summary.detail)
        XCTAssertFalse(summary.detail.contains("click"), "absent gaps are omitted, not shown empty")
    }

    func testAnInactiveRowNamesTheDepartureRatherThanTheCounts() {
        // The subject says what the row is *for*. "0 keys, 0 mouse" is
        // literally true of a departure and says nothing about it.
        let summary = ContextEventDetail.input(InputDetail(
            change: .inactive,
            secondsSinceKey: 200, secondsSinceMouseMove: 200,
            secondsSinceClick: nil, secondsSinceScroll: nil,
            keyCountDelta: 37, mouseCountDelta: 500, intervalMs: 600_000)).summary

        XCTAssertEqual(summary.subject, "No activity")
        XCTAssertTrue(summary.detail.contains("37 keys"), summary.detail)
        XCTAssertFalse(summary.detail.contains("already idle"),
                       "an ordinary departure carries no interval of its own")
    }

    func testAnInactiveRowFoundAlreadyQuietSaysHowLong() {
        let summary = ContextEventDetail.input(InputDetail(
            change: .inactive, idleSeconds: 3_600,
            secondsSinceKey: 3_600, secondsSinceMouseMove: 3_600,
            secondsSinceClick: nil, secondsSinceScroll: nil,
            keyCountDelta: nil, mouseCountDelta: nil, intervalMs: nil)).summary

        XCTAssertEqual(summary.subject, "No activity")
        XCTAssertTrue(summary.detail.contains("already idle"), summary.detail)
    }

    func testAnActiveRowReportsTheAbsenceItEnded() {
        let summary = ContextEventDetail.input(InputDetail(
            change: .active, idleSeconds: 1_500,
            secondsSinceKey: 0.1, secondsSinceMouseMove: 0.1,
            secondsSinceClick: nil, secondsSinceScroll: nil,
            keyCountDelta: 3, mouseCountDelta: 4, intervalMs: 1_500_000)).summary

        XCTAssertEqual(summary.subject, "Activity resumed")
        XCTAssertTrue(summary.detail.contains("away"), summary.detail)
    }

    func testSessionIsJustTheChange() {
        let summary = ContextEventDetail.session(SessionDetail(change: .lock)).summary
        XCTAssertEqual(summary.subject, "lock")
        XCTAssertEqual(summary.detail, "")
    }

    func testPowerCarriesTheChargeAndChargingState() {
        let summary = ContextEventDetail.power(
            PowerDetail(source: .battery, percent: 62, isCharging: false)).summary
        XCTAssertEqual(summary.subject, "battery")
        XCTAssertEqual(summary.detail, "62% · not charging")
    }

    func testEventSummaryIsItsDetailSummary() {
        let detail = ContextEventDetail.session(SessionDetail(change: .idle))
        let event = ContextEvent(machineID: UUID(), occurredAt: Date(), detail: detail)
        XCTAssertEqual(event.summary, detail.summary)
    }

    // MARK: - singleLine

    func testSingleLineIsSubjectAloneWhenThereIsNoDetail() {
        let summary = ContextEventSummary(subject: "lock", detail: "")
        XCTAssertEqual(summary.singleLine, "lock")
    }

    func testSingleLineJoinsSubjectAndDetailWithAnEmDash() {
        let summary = ContextEventSummary(subject: "iTerm2", detail: "tracking — zsh")
        XCTAssertEqual(summary.singleLine, "iTerm2 — tracking — zsh")
    }
}
