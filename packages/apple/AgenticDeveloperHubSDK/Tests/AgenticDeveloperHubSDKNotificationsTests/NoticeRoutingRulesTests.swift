import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeRoutingRulesTests: XCTestCase {

    private func notice(
        source: String = "ci", category: String? = nil, urgency: Notice.Urgency = .fyi
    ) -> Notice {
        Notice(source: source, title: "t", urgency: urgency, category: category)
    }

    private func decode(_ json: String) throws -> NoticeRoutingRules {
        try NoticeCoding.decoder.decode(NoticeRoutingRules.self, from: Data(json.utf8))
    }

    private func styles(_ set: NoticeStyleSet) -> [NoticeProfile.Style] {
        set.items.map(\.style)
    }

    // MARK: Defaults

    func testDefaultsMatchSpec() {
        let rules = NoticeRoutingRules.defaults
        let expected: [(Notice.Urgency, [NoticeProfile], TimeInterval?)] = [
            (.fyi, [NoticeProfile(style: .toast, position: .bottomRight, layer: .floating)], 8),
            (.eventually, [NoticeProfile(style: .toast, position: .bottomRight, layer: .floating)], nil),
            (.soon, [NoticeProfile(style: .toast, position: .bottomRight, layer: .floating)], nil),
            (.now, [NoticeProfile(style: .alert, position: .center, layer: .floating)], nil),
            (.emergency, [NoticeProfile(style: .fullScreen)], nil)
        ]
        for (urgency, items, dismiss) in expected {
            let set = rules.styles[urgency]
            XCTAssertEqual(set?.items, items, "\(urgency)")
            XCTAssertEqual(set?.autoDismiss, dismiss, "\(urgency)")
            XCTAssertEqual(set?.snooze, SnoozeSettings(isEnabled: true, options: SnoozeOption.allCases), "\(urgency)")
            XCTAssertEqual(NoticeRoutingRules.defaultStyle(for: urgency), set, "\(urgency)")
        }
        let fullScreen = rules.styles[.emergency]?.items.first?.fullScreen
        XCTAssertEqual(fullScreen, NoticeProfile.FullScreenAppearance(blur: 0.6, color: .system, opacity: 0.55))
        XCTAssertEqual(rules.screens, .all)
        XCTAssertEqual(rules.crawl, CrawlSettings(
            edge: .bottom, showsBackground: true, background: .theme, backgroundOpacity: 0.9,
            speed: 80, leftToRight: false, textSize: 13, itemOpacity: 1.0))
        XCTAssertEqual(rules.toastStackLimit, 4)
        XCTAssertEqual(rules.flood, FloodFolder.Configuration(threshold: 5, window: 10))
        XCTAssertEqual(rules.escalation.soonToNowAfter, 900)
        XCTAssertEqual(rules.escalation.eventuallyToSoonAfter, 0)
        XCTAssertTrue(rules.hideFromScreenSharing)
        XCTAssertNil(rules.legacyHotkeysEnabled)
        XCTAssertTrue(rules.overrides.isEmpty)
    }

    // MARK: Resolving a set

    func testFirstMatchingOverrideWins() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [
            .init(source: "ci", target: .style(.now)),
            .init(source: "ci", target: .hide)
        ]
        XCTAssertEqual(rules.style(for: notice()), rules.styles[.now])
        XCTAssertEqual(rules.style(for: notice(source: "other")), rules.styles[.fyi])
    }

    func testOverrideCategoryIsCaseInsensitive() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(category: "Builds", target: .style(.emergency))]
        XCTAssertEqual(styles(rules.style(for: notice(category: "bUILDS"))), [.fullScreen])
        XCTAssertEqual(styles(rules.style(for: notice(category: "other"))), [.toast])
        XCTAssertEqual(styles(rules.style(for: notice(category: nil))), [.toast])
    }

    func testEffectiveUrgencySelectsEscalatedSet() {
        let rules = NoticeRoutingRules.defaults
        let soon = notice(urgency: .soon)
        XCTAssertEqual(styles(rules.style(for: soon)), [.toast])
        XCTAssertEqual(styles(rules.style(for: soon, effectiveUrgency: .now)), [.alert])
    }

    func testOverrideUrgencyMatchesEffectiveUrgency() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(urgency: .now, target: .hide)]
        let soon = notice(urgency: .soon)
        XCTAssertEqual(styles(rules.style(for: soon)), [.toast])
        XCTAssertEqual(styles(rules.style(for: soon, effectiveUrgency: .now)), [])
    }

    func testStyleForHideOverrideIsEmptyButKeepsSnooze() {
        var rules = NoticeRoutingRules.defaults
        rules.styles[.fyi]?.snooze = SnoozeSettings(isEnabled: true, options: [.oneHour])
        rules.overrides = [.init(source: "ci", target: .hide)]
        let set = rules.style(for: notice(urgency: .fyi))
        XCTAssertTrue(set.items.isEmpty)
        XCTAssertEqual(set.snooze, SnoozeSettings(isEnabled: true, options: [.oneHour]))
        XCTAssertEqual(set.autoDismiss, 8, "the urgency set's dismiss carries over too")
    }

    func testSetFallsBackToDefaultWhenUrgencyIsMissing() {
        var rules = NoticeRoutingRules.defaults
        rules.styles = [.fyi: NoticeStyleSet(items: [NoticeProfile(style: .crawl)])]
        XCTAssertEqual(styles(rules.style(for: notice(urgency: .fyi))), [.crawl])
        XCTAssertEqual(rules.style(for: notice(urgency: .now)), NoticeRoutingRules.defaultStyle(for: .now))
    }

    // MARK: Legacy deliver setting

    func testDeliverMigrationAppendsSystemItemOnce() {
        let migrated = NoticeRoutingRules.migratingLegacyDeliverSetting(true, into: .defaults)
        XCTAssertEqual(styles(migrated.styles[.fyi]!), [.toast, .system])
        XCTAssertEqual(migrated.styles[.soon], NoticeRoutingRules.defaults.styles[.soon])

        let again = NoticeRoutingRules.migratingLegacyDeliverSetting(true, into: migrated)
        XCTAssertEqual(styles(again.styles[.fyi]!), [.toast, .system], "fyi already has a system item")
    }

    func testLegacyDeliverNilOrFalseChangesNothing() {
        XCTAssertEqual(NoticeRoutingRules.migratingLegacyDeliverSetting(nil, into: .defaults), .defaults)
        XCTAssertEqual(NoticeRoutingRules.migratingLegacyDeliverSetting(false, into: .defaults), .defaults)
    }

    func testDeliverMigrationLeavesOverridesAlone() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(source: "ci", target: .hide), .init(urgency: .fyi, target: .style(.now))]
        let migrated = NoticeRoutingRules.migratingLegacyDeliverSetting(true, into: rules)
        XCTAssertEqual(migrated.overrides, rules.overrides)
    }

    // MARK: Coding

    func testRoundTripEncodesOnlyNewShape() throws {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(source: "ci", category: "builds", urgency: .soon, target: .style(.now)),
                           .init(category: "noise", target: .hide)]
        rules.crawl.leftToRight = true
        rules.screens = .main
        let data = try NoticeCoding.encoder.encode(rules)
        XCTAssertEqual(try NoticeCoding.decoder.decode(NoticeRoutingRules.self, from: data), rules)

        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        for key in ["\"styles\"", "\"screens\"", "\"crawl\""] {
            XCTAssertTrue(json.contains(key), "missing \(key)")
        }
        for key in ["\"profiles\"", "\"crawlLeftToRight\"", "\"forwardToSystem\"", "\"legacyHotkeysEnabled\"",
                    "\"hotkeysEnabled\"", "\"autoDismiss\":8,\"layer\""] {
            XCTAssertFalse(json.contains(key), "still writes \(key)")
        }
        XCTAssertTrue(json.contains(#""fyi":{"#), "styles are keyed by urgency name, not a flat array")
    }

    func testPartialJSONDecodesToDefaultsForTheRest() throws {
        let rules = try decode(
            #"{"styles":{"soon":{"items":[{"style":"crawl"}],"autoDismiss":5}},"toastStackLimit":2}"#)
        XCTAssertEqual(styles(rules.styles[.soon]!), [.crawl])
        XCTAssertEqual(rules.styles[.soon]?.autoDismiss, 5)
        XCTAssertEqual(rules.styles[.soon]?.snooze, SnoozeSettings())
        XCTAssertEqual(rules.styles[.fyi], NoticeRoutingRules.defaults.styles[.fyi])
        XCTAssertEqual(rules.toastStackLimit, 2)
        XCTAssertEqual(rules.crawl, CrawlSettings())
        XCTAssertEqual(rules.screens, .all)
        XCTAssertTrue(rules.overrides.isEmpty)
    }

    func testEmptyJSONDecodesToDefaults() throws {
        XCTAssertEqual(try decode("{}"), .defaults)
    }

    func testUnknownPositionFallsBack() throws {
        let rules = try decode(#"{"styles":{"fyi":{"items":["#
            + #"{"style":"toast","position":"topRight"},"#
            + #"{"style":"alert","position":"bogus"},"#
            + #"{"style":"toast","position":"bogus"}]}}}"#)
        XCTAssertEqual(rules.styles[.fyi]?.items.map(\.position), [.bottomRight, .center, .bottomRight])
    }

    // MARK: 0.7.x migration

    /// A rules value exactly as 0.7.24 stored it.
    private static let legacy0724 = #"""
    {"crawlLeftToRight":true,"escalation":{"eventuallyToSoonAfter":0,"soonToNowAfter":900},
     "flood":{"threshold":5,"window":10},"hideFromScreenSharing":true,"hotkeysEnabled":true,
     "overrides":[
       {"source":"ci","profile":{"style":"none","position":"topRight","screens":"main","layer":"floating",
                                 "forwardToSystem":false}},
       {"category":"x","profile":{"style":"alert","position":"center","screens":"cursor","layer":"floating",
                                  "forwardToSystem":false}}],
     "profiles":{
       "fyi":{"style":"toast","position":"topRight","screens":"main","layer":"floating","autoDismiss":8,
              "forwardToSystem":true},
       "eventually":{"style":"none","position":"topRight","screens":"main","layer":"floating",
                     "forwardToSystem":false},
       "soon":{"style":"toast","position":"topRight","screens":"cursor","layer":"floating",
               "forwardToSystem":false},
       "now":{"style":"alert","position":"center","screens":"cursor","layer":"floating",
              "forwardToSystem":false},
       "emergency":{"style":"fullScreen","position":"center","screens":"all","layer":"floating",
                    "forwardToSystem":false}},
     "toastStackLimit":4}
    """#

    func testLegacy0724RulesMigrate() throws {
        let rules = try decode(Self.legacy0724)

        let fyi = try XCTUnwrap(rules.styles[.fyi])
        XCTAssertEqual(fyi.items, [NoticeProfile(style: .toast, position: .bottomRight), NoticeProfile(style: .system)])
        XCTAssertEqual(fyi.autoDismiss, 8)
        XCTAssertEqual(rules.styles[.eventually]?.items, [])
        XCTAssertEqual(rules.styles[.soon]?.items, [NoticeProfile(style: .toast, position: .bottomRight)])
        XCTAssertNil(rules.styles[.soon]?.autoDismiss)
        XCTAssertEqual(rules.styles[.now]?.items, [NoticeProfile(style: .alert, position: .center)])
        XCTAssertEqual(styles(rules.styles[.emergency]!), [.fullScreen])
        for urgency in Notice.Urgency.allCases {
            XCTAssertEqual(rules.styles[urgency]?.snooze, SnoozeSettings(), "\(urgency)")
        }
        XCTAssertEqual(rules.screens, .all)
        XCTAssertTrue(rules.crawl.leftToRight)
        XCTAssertEqual(rules.legacyHotkeysEnabled, true)
        XCTAssertEqual(rules.overrides, [
            .init(source: "ci", target: .hide), .init(category: "x", target: .style(.now))
        ])
        XCTAssertEqual(rules.toastStackLimit, 4)
    }

    /// Settings saved by 0.8.1-0.8.8 are in the new shape but still carry
    /// `hotkeysEnabled`; the keyboard migration must see it.
    func testBlobSavedBy08xSurfacesItsHotkeysFlag() throws {
        let enabled = try decode(#"{"styles":{},"screens":"all","hotkeysEnabled":true}"#)
        XCTAssertEqual(enabled.legacyHotkeysEnabled, true)
        let disabled = try decode(#"{"styles":{},"hotkeysEnabled":false}"#)
        XCTAssertEqual(disabled.legacyHotkeysEnabled, false)
        let none = try decode(#"{"styles":{}}"#)
        XCTAssertNil(none.legacyHotkeysEnabled)
    }

    func testLegacyMigrationIsCompletedByTheNextSave() throws {
        let migrated = try decode(Self.legacy0724)
        let data = try NoticeCoding.encoder.encode(migrated)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(json.contains("\"profiles\""))
        let reloaded = try NoticeCoding.decoder.decode(NoticeRoutingRules.self, from: data)
        XCTAssertEqual(reloaded.styles, migrated.styles)
        XCTAssertEqual(reloaded.overrides, migrated.overrides)
        XCTAssertEqual(reloaded.crawl, migrated.crawl)
        XCTAssertNil(reloaded.legacyHotkeysEnabled, "surfaced once, never written back")
    }

    func testLegacyAllMainScreensMigratesToMain() throws {
        let profile = #"{"style":"toast","position":"bottomLeft","screens":"main","layer":"normal"}"#
        let json = #"{"profiles":{"fyi":\#(profile),"eventually":\#(profile),"soon":\#(profile),"#
            + #""now":\#(profile),"emergency":\#(profile)}}"#
        let rules = try decode(json)
        XCTAssertEqual(rules.screens, .main)
        XCTAssertEqual(rules.styles[.now]?.items, [NoticeProfile(style: .toast, position: .bottomLeft, layer: .normal)])
        XCTAssertNil(rules.legacyHotkeysEnabled, "absent in the blob, so not surfaced")
        XCTAssertFalse(rules.crawl.leftToRight)
    }

    func testLegacyPartialProfilesKeepDefaultsForTheRest() throws {
        let rules = try decode(#"{"profiles":{"soon":{"style":"crawl","position":"topLeft","screens":"all","#
            + #""layer":"normal","forwardToSystem":true}}}"#)
        XCTAssertEqual(rules.styles[.soon]?.items, [
            NoticeProfile(style: .crawl, position: .topLeft, layer: .normal), NoticeProfile(style: .system)
        ])
        XCTAssertEqual(rules.styles[.fyi], NoticeRoutingRules.defaults.styles[.fyi])
        XCTAssertEqual(rules.screens, .all)
    }

    func testLegacySystemStyleWithForwardingAddsNoSecondSystemItem() throws {
        let rules = try decode(#"{"profiles":{"fyi":{"style":"system","position":"topRight","screens":"main","#
            + #""layer":"floating","forwardToSystem":true}}}"#)
        XCTAssertEqual(styles(rules.styles[.fyi]!), [.system])
    }

    func testLegacyOverrideWithNoMatchingUrgencyTargetsFyi() throws {
        let rules = try decode(#"{"profiles":{},"overrides":[{"source":"ci","profile":{"style":"crawl","#
            + #""position":"topRight","screens":"main","layer":"floating","forwardToSystem":false}}]}"#)
        XCTAssertEqual(rules.overrides, [.init(source: "ci", target: .style(.fyi))])
    }
}
