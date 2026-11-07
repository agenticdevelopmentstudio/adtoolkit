import Foundation

/// Which style set presents which notice: one set per urgency, plus an
/// ordered list of overrides that are tried first.
public struct NoticeRoutingRules: Codable, Sendable, Equatable {

    /// Narrows by source, category and/or urgency. Every non-nil field must match.
    public struct Override: Codable, Sendable, Equatable {

        /// What a matching notice gets: another urgency's set, or nothing.
        public enum Target: Sendable, Equatable, Hashable, Codable {
            case style(Notice.Urgency)
            case hide

            /// Coded as one string: an urgency's raw value, or `hide`.
            public init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)
                if raw == "hide" {
                    self = .hide
                } else if let urgency = Notice.Urgency(rawValue: raw) {
                    self = .style(urgency)
                } else {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: decoder.codingPath, debugDescription: "unknown override target \(raw)"))
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .hide: try container.encode("hide")
                case .style(let urgency): try container.encode(urgency.rawValue)
                }
            }
        }

        public var source: String?
        public var category: String?
        public var urgency: Notice.Urgency?
        public var target: Target

        public init(
            source: String? = nil,
            category: String? = nil,
            urgency: Notice.Urgency? = nil,
            target: Target
        ) {
            self.source = source
            self.category = category
            self.urgency = urgency
            self.target = target
        }

        func matches(_ notice: Notice, urgency effective: Notice.Urgency) -> Bool {
            if let source, source != notice.source { return false }
            if let category {
                guard let found = notice.category, found.lowercased() == category.lowercased() else { return false }
            }
            if let urgency, urgency != effective { return false }
            return true
        }
    }

    public typealias ScreenSelection = NoticeProfile.ScreenSelection

    public var styles: [Notice.Urgency: NoticeStyleSet]
    public var overrides: [Override]
    /// Which screens toasts, alerts, the crawl and full screen present on.
    public var screens: ScreenSelection
    public var crawl: CrawlSettings
    public var toastStackLimit: Int
    public var flood: FloodFolder.Configuration
    public var escalation: EscalationPolicy
    public var hideFromScreenSharing: Bool
    /// The `hotkeysEnabled` switch a 0.7.x or 0.8.x build stored, surfaced by
    /// the decoder for the keyboard migration. Decoded only, never encoded.
    public var legacyHotkeysEnabled: Bool?

    public init(
        styles: [Notice.Urgency: NoticeStyleSet],
        overrides: [Override] = [],
        screens: ScreenSelection = .all,
        crawl: CrawlSettings = .init(),
        toastStackLimit: Int = 4,
        flood: FloodFolder.Configuration = .init(),
        escalation: EscalationPolicy = .init(),
        hideFromScreenSharing: Bool = true,
        legacyHotkeysEnabled: Bool? = nil
    ) {
        self.styles = styles
        self.overrides = overrides
        self.screens = screens
        self.crawl = crawl
        self.toastStackLimit = toastStackLimit
        self.flood = flood
        self.escalation = escalation
        self.hideFromScreenSharing = hideFromScreenSharing
        self.legacyHotkeysEnabled = legacyHotkeysEnabled
    }

    /// The built-in set for an urgency, before any user change.
    public static func defaultStyle(for urgency: Notice.Urgency) -> NoticeStyleSet {
        let toast = NoticeProfile(style: .toast, position: .bottomRight, layer: .floating)
        switch urgency {
        case .fyi: return NoticeStyleSet(items: [toast], autoDismiss: 8)
        case .eventually, .soon: return NoticeStyleSet(items: [toast])
        case .now: return NoticeStyleSet(items: [NoticeProfile(style: .alert, position: .center, layer: .floating)])
        case .emergency: return NoticeStyleSet(items: [NoticeProfile(style: .fullScreen)])
        }
    }

    public static let defaults = NoticeRoutingRules(
        styles: Dictionary(uniqueKeysWithValues: Notice.Urgency.allCases.map { ($0, defaultStyle(for: $0)) })
    )

    /// The set that presents `notice`. `effectiveUrgency` stands in for the
    /// stored urgency when escalation has raised it. The first matching
    /// override wins; `.hide` keeps the urgency set's snooze and dismiss.
    public func style(for notice: Notice, effectiveUrgency: Notice.Urgency? = nil) -> NoticeStyleSet {
        let urgency = effectiveUrgency ?? notice.urgency
        if let match = overrides.first(where: { $0.matches(notice, urgency: urgency) }) {
            switch match.target {
            case .hide: return set(for: urgency).hidden
            case .style(let target): return set(for: target)
            }
        }
        return set(for: urgency)
    }

    private func set(for urgency: Notice.Urgency) -> NoticeStyleSet {
        styles[urgency] ?? Self.defaultStyle(for: urgency)
    }

    /// The retired "deliver notifications" setting defaulted to true, so only a
    /// stored `true` is a choice worth carrying over: it adds a Notification
    /// Center item to `fyi`'s set, once. `nil` and `false` leave the rules alone.
    public static func migratingLegacyDeliverSetting(
        _ value: Bool?, into rules: NoticeRoutingRules
    ) -> NoticeRoutingRules {
        guard value == true else { return rules }
        var migrated = rules
        var fyi = migrated.set(for: .fyi)
        if !fyi.items.contains(where: { $0.style == .system }) {
            fyi.items.append(NoticeProfile(style: .system))
        }
        migrated.styles[.fyi] = fyi
        return migrated
    }

    // MARK: Coding
    //
    // A dictionary keyed by a String-backed enum encodes as a flat array, which
    // is unreadable and order-dependent on the wire. Key it by raw value.

    private enum CodingKeys: String, CodingKey {
        case styles, overrides, screens, crawl, toastStackLimit, flood, escalation
        case hideFromScreenSharing
        /// Decode-only: 0.8.1-0.8.8 wrote it beside the new shape.
        case hotkeysEnabled
    }

    /// Every key is optional, falling back to `defaults`, so rules stored by an
    /// older build survive fields added later. Urgencies missing from
    /// `styles` take that urgency's default set. A 0.7.x value (with
    /// `profiles` and no `styles`) is converted by `decodeLegacy(from:)`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = Self.defaults
        let legacy = try Self.decodeLegacy(from: decoder)
        if let legacy {
            self.styles = legacy.styles
            self.overrides = legacy.overrides
            self.screens = legacy.screens
            var crawl = CrawlSettings()
            crawl.leftToRight = legacy.crawlLeftToRight ?? crawl.leftToRight
            self.crawl = crawl
            self.legacyHotkeysEnabled = legacy.hotkeysEnabled
        } else {
            let raw = try container.decodeIfPresent([String: NoticeStyleSet].self, forKey: .styles) ?? [:]
            var decoded: [Notice.Urgency: NoticeStyleSet] = [:]
            for urgency in Notice.Urgency.allCases {
                decoded[urgency] = raw[urgency.rawValue] ?? Self.defaultStyle(for: urgency)
            }
            self.styles = decoded
            // An override this build can't read (an unknown target, say) is skipped.
            self.overrides = try container.decodeLossyArrayIfPresent([Override].self, forKey: .overrides)
                ?? base.overrides
            self.screens = try container.decodeIfPresent(String.self, forKey: .screens)
                .flatMap(ScreenSelection.init(rawValue:)) ?? base.screens
            self.crawl = try container.decodeIfPresent(CrawlSettings.self, forKey: .crawl) ?? base.crawl
            self.legacyHotkeysEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotkeysEnabled)
        }
        self.toastStackLimit = try container.decodeIfPresent(Int.self, forKey: .toastStackLimit)
            ?? base.toastStackLimit
        self.flood = try container.decodeIfPresent(FloodFolder.Configuration.self, forKey: .flood) ?? base.flood
        self.escalation = try container.decodeIfPresent(EscalationPolicy.self, forKey: .escalation)
            ?? base.escalation
        self.hideFromScreenSharing = try container.decodeIfPresent(Bool.self, forKey: .hideFromScreenSharing)
            ?? base.hideFromScreenSharing
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            Dictionary(uniqueKeysWithValues: styles.map { ($0.key.rawValue, $0.value) }),
            forKey: .styles
        )
        try container.encode(overrides, forKey: .overrides)
        try container.encode(screens, forKey: .screens)
        try container.encode(crawl, forKey: .crawl)
        try container.encode(toastStackLimit, forKey: .toastStackLimit)
        try container.encode(flood, forKey: .flood)
        try container.encode(escalation, forKey: .escalation)
        try container.encode(hideFromScreenSharing, forKey: .hideFromScreenSharing)
    }
}
