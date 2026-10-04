import Foundation

/// A context event rendered for a human, in two parts.
///
/// Lives in AgenticToolkitActivity rather than in the macOS log window because it is the
/// answer to "what does this row say", which iOS, a future Android/Windows
/// client, and any export or sync surface all need — none of them share the
/// window's AppKit code. The window keeps only the part that is genuinely
/// AppKit: fonts, colours and column widths.
///
/// Two fields rather than one string so a table can give the identity its own
/// sortable, fixed-width column and let the long tail truncate.
public struct ContextEventSummary: Sendable, Equatable {
    /// Who or what the event is about: the app, the network, the state that
    /// changed. Short enough for a narrow column; never empty (falls back to
    /// the kind's own name when the event carries no identity of its own).
    public let subject: String

    /// Everything else worth showing, joined with " · ". May be empty.
    public let detail: String

    public init(subject: String, detail: String) {
        self.subject = subject
        self.detail = detail
    }
}

public extension ContextEventSummary {
    /// `subject` alone when there is nothing else to say; otherwise `subject`
    /// and `detail` joined with an em dash. What a single-line table column
    /// (the timeline's Title column, and any future one like it) renders —
    /// the counterpart to keeping the two parts separate above, which exists
    /// for callers that want the identity in its own sortable column instead.
    var singleLine: String {
        detail.isEmpty ? subject : "\(subject) — \(detail)"
    }
}

public extension ContextEventKind {
    /// Title-case name for menus, filters and column values. Derived from the
    /// schema raw value rather than a second hand-maintained list, so a new
    /// kind cannot ship with a missing label.
    var displayName: String {
        rawValue.split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

public extension ContextEvent {
    var summary: ContextEventSummary { detail.summary }
}

public extension ContextEventDetail {
    var summary: ContextEventSummary {
        switch self {
        case .appFocus(let d):
            return Self.rendered(
                subject: Self.firstNonEmpty(d.appName, d.bundleID, kind.displayName),
                detail: [
                    d.windowTitle.flatMap(Self.quoted),
                    d.bundleID.isEmpty ? nil : d.bundleID,
                    d.url,
                    d.documentPath,
                    d.documentSize.map { "\($0) bytes" },
                    d.documentType
                ])

        case .window(let d):
            // The window title is tried before the kind's name because a row
            // whose subject reads "Window" says nothing at all. Rows recorded
            // for a window that opened before the observation started carry no
            // app, and the title is the only identity they have. When it is
            // promoted to the subject it is dropped from the detail rather
            // than printed twice.
            let app = Self.firstNonEmpty(d.appName, d.bundleID)
            let title = d.windowTitle ?? ""
            return Self.rendered(
                subject: Self.firstNonEmpty(app, title, kind.displayName),
                detail: [
                    d.change.rawValue,
                    app.isEmpty ? nil : d.windowTitle.flatMap(Self.quoted),
                    "window \(d.windowID)"
                ])

        case .network(let d):
            return Self.rendered(
                // The SSID is the label the user actually recognises ("home",
                // "Foo Corp"), so it leads when there is one; the interface
                // type is the fallback identity, not the headline.
                subject: Self.firstNonEmpty(d.ssid ?? "", d.interfaceType.rawValue),
                detail: [
                    d.interfaceType.rawValue,
                    d.isSatisfied ? "reachable" : "unreachable",
                    d.bssid,
                    (d.isExpensive == true) ? "expensive" : nil,
                    (d.isConstrained == true) ? "constrained" : nil
                ])

        case .location(let d):
            return Self.rendered(
                subject: "\(Self.fixed(d.latitude, places: 5)), \(Self.fixed(d.longitude, places: 5))",
                detail: [
                    d.horizontalAccuracy.map { "±\(Self.fixed($0, places: 0)) m" },
                    d.altitude.map { "alt \(Self.fixed($0, places: 0)) m" },
                    d.speed.map { "\(Self.fixed($0, places: 1)) m/s" },
                    d.course.map { "course \(Self.fixed($0, places: 0))°" }
                ])

        case .input(let d):
            // The counts are detail on every input row; the subject says what
            // the row is *for*. A transition's subject is the transition. A
            // legacy `sample` row has no event to name, so it keeps falling
            // back to the counts it was written to carry.
            let counts = [
                d.keyCountDelta.map { "\($0) keys" },
                d.mouseCountDelta.map { "\($0) mouse" }
            ]
            switch d.change {
            case .inactive:
                return Self.rendered(
                    subject: "No activity",
                    // Nil on an ordinary row, which simply marks where
                    // activity stopped. It is set only when the trigger found
                    // the machine already quiet at startup — and then it is
                    // the one thing on the row worth saying.
                    detail: [d.idleSeconds.map { "already idle \(TimelineFormat.formatted(duration: $0))" }]
                        + counts)
            case .active:
                return Self.rendered(
                    subject: "Activity resumed",
                    detail: [d.idleSeconds.map { "after \(TimelineFormat.formatted(duration: $0)) away" }]
                        + counts)
            case .sample:
                return Self.rendered(
                    subject: Self.join(counts, separator: ", ", fallback: kind.displayName),
                    detail: [
                        d.secondsSinceKey.map { "key \(Self.fixed($0, places: 1))s ago" },
                        d.secondsSinceMouseMove.map { "move \(Self.fixed($0, places: 1))s ago" },
                        d.secondsSinceClick.map { "click \(Self.fixed($0, places: 1))s ago" },
                        d.secondsSinceScroll.map { "scroll \(Self.fixed($0, places: 1))s ago" },
                        d.intervalMs.map { "over \($0) ms" }
                    ])
            }

        case .session(let d):
            return Self.rendered(subject: d.change.rawValue, detail: [])

        case .power(let d):
            return Self.rendered(
                subject: d.source.rawValue,
                detail: [
                    d.percent.map { "\($0)%" },
                    d.isCharging.map { $0 ? "charging" : "not charging" }
                ])

        case .appLifecycle(let d):
            return Self.rendered(
                subject: Self.firstNonEmpty(d.appName, d.bundleID, kind.displayName),
                detail: [
                    d.change.rawValue,
                    d.bundleID.isEmpty ? nil : d.bundleID,
                    "pid \(d.pid)"
                ])
        }
    }

    // MARK: - Formatting helpers

    /// The single constructor every case goes through, so the invariant holds
    /// by construction: a detail part that merely repeats the subject is
    /// dropped, never printed twice.
    ///
    /// This used to be each case's own business, and two of them got it wrong.
    /// `app_focus` and `app_lifecycle` both list the bundle id in the detail
    /// and both fall back to it for the subject when the app has no name, so a
    /// nameless app rendered "com.example.headless — com.example.headless".
    /// `window` and `network` avoided the same collision with ad-hoc guards
    /// written into their own part lists — the rule was known, it was just
    /// stated in one place per case instead of once.
    ///
    /// Comparing whole parts rather than searching the joined string: a
    /// window title that happens to contain the app's name is a real detail,
    /// not a repetition.
    private static func rendered(subject: String, detail parts: [String?],
                                 separator: String = " · ") -> ContextEventSummary {
        ContextEventSummary(
            subject: subject,
            detail: join(parts.map { $0 == subject ? nil : $0 }, separator: separator))
    }


    /// `String(format:)` with an explicit POSIX locale: these strings are
    /// read next to raw database values, and a locale that renders `12,5`
    /// would not round-trip against them.
    private static func fixed(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private static func quoted(_ text: String) -> String? {
        text.isEmpty ? nil : "“\(text)”"
    }

    private static func firstNonEmpty(_ candidates: String...) -> String {
        candidates.first { !$0.isEmpty } ?? ""
    }

    private static func join(_ parts: [String?],
                             separator: String = " · ",
                             fallback: String = "") -> String {
        let kept = parts.compactMap { $0 }.filter { !$0.isEmpty }
        return kept.isEmpty ? fallback : kept.joined(separator: separator)
    }
}
