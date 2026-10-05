import Foundation

/// What one entry covers. Switchable at any time: it only decides how the
/// *next* pass groups, so nothing already written changes meaning.
public enum BillingGranularity: String, Sendable {
    case day
    case run
}

public struct BillingRollupOptions: Sendable, Equatable {
    public let granularity: BillingGranularity
    /// Used only when neither the repo nor the project names a rate.
    public let defaultRateCents: Int
    public let currency: String

    public init(granularity: BillingGranularity = .day, defaultRateCents: Int = 0, currency: String = "USD") {
        self.granularity = granularity
        self.defaultRateCents = defaultRateCents
        self.currency = currency
    }
}

/// Turns closed, assigned segments into billing entries.
///
/// The whole type rests on one rule: an entry at `unbilled` is a *view* of its
/// segments and may be recomputed on every pass; an entry past `unbilled` is
/// *history* and is never recomputed, never edited, and never silently grown.
/// Late work on a frozen day becomes a supplemental entry you can see.
///
/// Who bills each second is decided per project day by `settleDay`: frozen
/// entries own what they recorded, Claude-side time owns the rest of its
/// runs, and app time owns the residual — so every second bills exactly once,
/// on whichever day each entry is listed.
public enum BillingRollup {

    public enum RollupError: LocalizedError {
        case unknownEntry(String)
        case entryIsLocked(String)
        case statusChangeNotAllowed(current: String, requested: String)
        case entryChanged(String)
        case entryHasFrozenSupplements(id: String, count: Int)

        public var errorDescription: String? {
            switch self {
            case .unknownEntry:
                return BillingRefusalText.unknownEntry
            case .entryIsLocked:
                return BillingRefusalText.entryIsLocked
            case .statusChangeNotAllowed(let current, let requested):
                return BillingRefusalText.statusChangeNotAllowed(current: current, requested: requested)
            case .entryChanged:
                return "This entry changed since you opened it. Review the new figures and save again."
            case .entryHasFrozenSupplements(_, let count):
                let supplements = count == 1 ? "a supplement that is" : "\(count) supplements that are"
                return "This entry has \(supplements) billed, paid or edited by hand. Delete those first."
            }
        }
    }

    // MARK: - The pass

    /// Rolls every eligible segment, then settles the days the rollup must
    /// look at again — every day a settle could still change
    /// (`billingUnsettledDays`: an all-frozen, fully billed day is skipped),
    /// or only those of `recomputing` when the caller knows which entries its
    /// derivation can have touched (`BillingTask`). The full sweep over every
    /// day is `recomputeOwnedEntries`. Returns the number of entries created, recomputed or
    /// removed — zero is the normal steady state.
    @discardableResult
    public static func run(
        options: BillingRollupOptions, database: any BillingPersistence, recomputing: Set<String>? = nil
    ) throws -> Int {
        let rolled = try roll(try database.billingRollupCandidates(ids: nil), options: options, database: database)
        let days = try recomputing.map { try projectDays(of: $0, database: database) }
            ?? Set(try database.billingUnsettledDays())
        return rolled.count + (try settleCascading(days.subtracting(rolled.days), database: database))
    }

    /// The same pass restricted to named segments — what the Billing Activity
    /// window's "Create billable" button runs after assigning an orphan.
    @discardableResult
    public static func promoteSegments(
        ids: [String], options: BillingRollupOptions, database: any BillingPersistence
    ) throws -> Int {
        guard !ids.isEmpty else { return 0 }
        return try roll(try database.billingRollupCandidates(ids: ids), options: options, database: database).count
    }

    private struct Slot: Hashable {
        let projectId: String
        let day: String
        let groupKey: String
        /// The rate this slot's time bills at, resolved per segment. Part of
        /// the slot (and, at day granularity, of `groupKey`), so one entry
        /// never mixes two rates.
        let rateCents: Int

        var projectDay: BillingProjectDay { BillingProjectDay(projectId: projectId, day: day) }
    }

    /// A derived run's identity is `(session_id, started_at)` — the same pair
    /// `idx_billing_segment_auto_identity` enforces, and what survives
    /// re-derivation. A manual timer is never re-derived, so its id is stable
    /// and, unlike its start, cannot collide with another timer's.
    public static func runGroupKey(for segment: BillingSegmentDTO) -> String {
        segment.origin == BillingSegmentDTO.autoOrigin ? "\(segment.sessionId)|\(segment.startedAt)" : segment.id
    }

    /// At run granularity, app time is not a run: it arrives as dozens of short
    /// focus spans an hour. Billed one entry per span, each rounded up on its
    /// own, forty two-minute spans became ten billed hours. So app time keeps
    /// day grouping — one entry per project, day and rate, unioned and rounded
    /// once — under a key of its own, beside the per-run Claude entries.
    public static func appGroupKey(rateCents: Int) -> String { appGroupPrefix + dayGroupKey(rateCents: rateCents) }

    static let appGroupPrefix = "app|"

    /// Whether `groupKey` names a run-granularity app entry.
    public static func isAppGroupKey(_ groupKey: String) -> Bool { groupKey.hasPrefix(appGroupPrefix) }

    /// A segment derived from an app-focus span (`app:` + span id).
    static func isAppSegment(_ segment: BillingSegmentDTO) -> Bool {
        segment.origin == BillingSegmentDTO.autoOrigin
            && ActivitySpanSession.spanId(sessionId: segment.sessionId) != nil
    }

    /// Frozen: billed or paid (`locked`), or with figures the user typed
    /// (`origin = "user"`). A frozen entry is history — it owns exactly the
    /// ranges recorded when it froze, and nothing ever changes it again.
    public static func isFrozen(_ entry: BillingEntryDTO) -> Bool { entry.locked || entry.origin == "user" }

    /// What a roll did: how many entries it wrote, and the days it settled.
    private struct Rolled {
        var count = 0
        var days: Set<BillingProjectDay> = []
    }

    private static func roll(
        _ candidates: [BillingSegmentDTO], options: BillingRollupOptions, database: any BillingPersistence
    ) throws -> Rolled {
        guard !candidates.isEmpty else { return Rolled() }

        let repos = try database.billingRepos(projectId: nil)
        var projects: [String: BillingProjectDTO?] = [:]
        var grouped: [Slot: [BillingSegmentDTO]] = [:]
        var order: [Slot] = []
        for segment in candidates {
            guard let projectId = segment.projectId, !projectId.isEmpty else { continue }
            if projects[projectId] == nil { projects[projectId] = .some(try database.billingProject(id: projectId)) }
            let project = projects[projectId] ?? nil
            let rate = BillingRate.rateCents(
                repo: segment.repoId.flatMap { id in repos.first { $0.id == id } },
                repos: repos,
                project: project,
                globalDefaultRateCents: options.defaultRateCents
            )
            let groupKey: String
            switch options.granularity {
            case .run:
                // At run granularity the run *is* the group, which is why
                // `group_key` exists: two runs on one day would otherwise
                // collide on the project-day unique index. Keyed on the run's
                // stable identity, never a row id a rewrite could replace.
                // App time is the exception: see `appGroupKey`.
                groupKey = isAppSegment(segment) ? appGroupKey(rateCents: rate) : runGroupKey(for: segment)
            case .day:
                // One entry per project, day **and rate**, always keyed by the
                // rate itself. A key meaning "the project's *current* default"
                // made a default-rate change route new time into the entry
                // holding time at the old rate, repricing all of it.
                groupKey = dayGroupKey(rateCents: rate)
            }
            let slot = Slot(
                projectId: projectId,
                day: BillingClock.localDay(utc: segment.startedAt, tz: segment.tz),
                groupKey: groupKey,
                rateCents: rate
            )
            if grouped[slot] == nil { order.append(slot) }
            grouped[slot, default: []].append(segment)
        }

        // One write transaction per project day: every slot's segments are
        // attached, then the day's ownership is settled, so no reader ever
        // sees time attached but not yet billed once.
        // Earliest day first: a day bills around the days before it, so those
        // are settled before it is.
        var slotsByDay: [BillingProjectDay: [Slot]] = [:]
        for slot in order { slotsByDay[slot.projectDay, default: []].append(slot) }
        var rolled = Rolled()
        var followUps: Set<BillingProjectDay> = []
        // A later project day failing must not strand the follow-ups of the
        // days already committed: an earlier day still holding app time a
        // committed day's run took would bill it twice until settled again.
        do {
            try rollDays(slotsByDay, grouped: grouped, projects: projects, options: options,
                         database: database, rolled: &rolled, followUps: &followUps)
        } catch {
            _ = try? settleCascading(followUps, database: database)
            throw error
        }
        rolled.count += try settleCascading(followUps, database: database)
        return rolled
    }

    /// `roll`'s loop: one write transaction per project day, earliest first.
    private static func rollDays(
        _ slotsByDay: [BillingProjectDay: [Slot]], grouped: [Slot: [BillingSegmentDTO]],
        projects: [String: BillingProjectDTO?], options: BillingRollupOptions, database: any BillingPersistence,
        rolled: inout Rolled, followUps: inout Set<BillingProjectDay>
    ) throws {
        for projectDay in slotsByDay.keys.sorted(by: earlier) {
            try database.transaction {
                // The days of the entries that took time: the slot's own,
                // or another where a frozen owner's open supplement is
                // listed (it may have been moved off the slot's day).
                var receivers: Set<BillingProjectDay> = []
                for slot in slotsByDay[projectDay] ?? [] {
                    if let day = try attach(
                        grouped[slot] ?? [], to: slot, project: projects[slot.projectId] ?? nil,
                        options: options, database: database
                    ) {
                        receivers.insert(BillingProjectDay(projectId: slot.projectId, day: day))
                    }
                }
                for receiver in receivers.sorted(by: earlier) {
                    let settled = try settleDay(receiver, database: database)
                    rolled.count += settled.changed
                    rolled.days.insert(receiver)
                    if settled.changed > 0 { followUps.formUnion(around(receiver, settled: settled)) }
                }
            }
        }
    }

    /// The day-granularity key for time billed at `rateCents`.
    public static func dayGroupKey(rateCents: Int) -> String { "rate:\(rateCents)" }

    /// Attaches one group's segments to the entry that should hold them,
    /// creating it if there is none. The figures are `settleDay`'s, written
    /// right after in the same transaction. Returns the day the receiving
    /// entry is listed on — not always the slot's: a frozen owner's open
    /// supplement can sit on another — or nil when nothing attached.
    ///
    /// The segments are re-read inside the caller's write transaction. Read
    /// on a snapshot, a Mark Billed committed in between was undone by the
    /// write, and a promote racing the task pass double-counted a segment or
    /// collided on the slot's unique index.
    private static func attach(
        _ segments: [BillingSegmentDTO],
        to slot: Slot,
        project: BillingProjectDTO?,
        options: BillingRollupOptions,
        database: any BillingPersistence
    ) throws -> String? {
        // Still unattached, still billable, still where they were grouped:
        // another writer may have rolled, re-derived or reassigned them, or
        // deleted the project, since the candidate read.
        let grouped = Dictionary(segments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let fresh = try database.billingRollupCandidates(ids: segments.map(\.id)).filter { segment in
            guard let original = grouped[segment.id] else { return false }
            return segment.projectId == slot.projectId && segment.repoId == original.repoId
                && segment.startedAt == original.startedAt && segment.tz == original.tz
        }
        guard !fresh.isEmpty else { return nil }

        let owner = try slotOwner(slot, database: database)

        // A frozen owner never grows. Its later time goes to a supplement you
        // can see.
        let target: StoredBillingEntry?
        let supplements: String?
        if let owner, isFrozen(owner.entry) {
            target = try database.billingOpenSupplement(of: owner.entry.id)
            supplements = owner.entry.id
        } else {
            target = owner
            supplements = owner?.entry.supplementsEntryId
        }

        let entryId: String
        let day: String
        if let target {
            entryId = target.entry.id
            day = target.entry.day
            // A legacy `''` day entry is re-keyed the first time it takes time.
            if target.entry.supplementsEntryId == nil, target.entry.groupKey != slot.groupKey {
                guard try database.upsertBillingEntry(
                    rewritten(target.entry, groupKey: slot.groupKey), overwrite: .rollupOwned
                ) else { return nil }
            }
        } else {
            let entry = try compose(
                slot: slot, supplements: supplements, project: project, options: options, database: database
            )
            // The entry row goes in first: a segment may only point at an
            // entry that exists.
            guard try database.upsertBillingEntry(entry, overwrite: .rollupOwned) else { return nil }
            entryId = entry.id
            day = entry.day
        }
        try database.attachSegments(ids: fresh.map(\.id), toEntry: entryId)
        return day
    }

    /// The entry owning `slot`. A day entry written before day keys carried
    /// the rate has the plain `''` key; it still owns time at its own
    /// snapshotted rate, and is re-keyed when the rollup next writes it.
    private static func slotOwner(
        _ slot: Slot, database: any BillingPersistence
    ) throws -> StoredBillingEntry? {
        if let owner = try database.billingEntryForSlot(
            projectId: slot.projectId, day: slot.day, groupKey: slot.groupKey
        ) {
            return owner
        }
        guard slot.groupKey == dayGroupKey(rateCents: slot.rateCents),
              let legacy = try database.billingEntryForSlot(projectId: slot.projectId, day: slot.day, groupKey: ""),
              legacy.entry.rateCents == slot.rateCents else { return nil }
        return legacy
    }

    /// A new, empty entry for one group; `settleDay` writes its figures.
    /// Everything rate-shaped is *snapshotted* here, the first time the entry
    /// is written, and never read through a reference again — that is what
    /// lets a rate change in March leave January's numbers alone, even when
    /// January's time is re-derived and re-rolled.
    private static func compose(
        slot: Slot,
        supplements: String?,
        project: BillingProjectDTO?,
        options: BillingRollupOptions,
        database: any BillingPersistence
    ) throws -> BillingEntryDTO {
        let now = UTCTimestamp.now()
        return BillingEntryDTO(
            id: UUID().uuidString,
            projectId: slot.projectId,
            clientId: project?.clientId,
            day: slot.day,
            groupKey: slot.groupKey,
            startedAt: "",
            endedAt: "",
            rawSeconds: 0,
            billedSeconds: 0,
            rateCents: slot.rateCents,
            currency: try currencyCode(for: project, fallback: options.currency, database: database),
            amountCents: 0,
            roundingMinutes: project?.roundingMinutes ?? 15,
            roundingMode: project?.roundingMode ?? "up",
            status: BillingStatus.unbilled.rawValue,
            description: "",
            origin: "auto",
            locked: false,
            supplementsEntryId: supplements,
            createdAt: now,
            updatedAt: now
        )
    }

    /// `entry` with new figures, description or key; everything else kept.
    private static func rewritten(
        _ entry: BillingEntryDTO, groupKey: String? = nil, figures: Figures? = nil, description: String? = nil
    ) -> BillingEntryDTO {
        BillingEntryDTO(
            id: entry.id,
            projectId: entry.projectId,
            clientId: entry.clientId,
            day: entry.day,
            groupKey: groupKey ?? entry.groupKey,
            startedAt: figures?.startedAt ?? entry.startedAt,
            endedAt: figures?.endedAt ?? entry.endedAt,
            rawSeconds: figures?.raw ?? entry.rawSeconds,
            billedSeconds: figures?.billed ?? entry.billedSeconds,
            rateCents: entry.rateCents,
            currency: entry.currency,
            amountCents: figures?.amount ?? entry.amountCents,
            roundingMinutes: entry.roundingMinutes,
            roundingMode: entry.roundingMode,
            status: entry.status,
            description: description ?? entry.description,
            origin: entry.origin,
            locked: entry.locked,
            supplementsEntryId: entry.supplementsEntryId,
            createdAt: entry.createdAt,
            updatedAt: UTCTimestamp.now()
        )
    }

    // MARK: - Ownership

    /// The project days of `ids`' entries.
    private static func projectDays(
        of ids: Set<String>, database: any BillingPersistence
    ) throws -> Set<BillingProjectDay> {
        var days: Set<BillingProjectDay> = []
        for id in ids {
            guard let entry = try database.billingEntry(id: id) else { continue }
            days.insert(BillingProjectDay(projectId: entry.projectId, day: entry.day))
        }
        return days
    }

    /// Total order on project days: by project, then calendar day.
    private static func earlier(_ lhs: BillingProjectDay, _ rhs: BillingProjectDay) -> Bool {
        (lhs.projectId, lhs.day) < (rhs.projectId, rhs.day)
    }

    /// The calendar day after `day` (`YYYY-MM-DD`).
    private static func dayAfter(_ day: String) -> String? {
        guard let noon = UTCTimestamp.epochSeconds(day + "T12:00:00Z") else { return nil }
        return String(UTCTimestamp.string(epochSeconds: noon + 86_400).prefix(10))
    }

    /// The days to settle again once `projectDay` changed: the next calendar
    /// day (a run crossing midnight reaches into it) and every later day
    /// whose entries overlap it. Always later, so a cascade only moves on.
    private static func after(
        _ projectDay: BillingProjectDay, later: Set<String>
    ) -> Set<BillingProjectDay> {
        var days = later
        if let next = dayAfter(projectDay.day) { days.insert(next) }
        return Set(days.filter { $0 > projectDay.day }.map {
            BillingProjectDay(projectId: projectDay.projectId, day: $0)
        })
    }

    /// The days to settle again once `projectDay` changed: those `after` it,
    /// and the earlier days whose app time its runs reach (Ruling 21). An
    /// earlier day settles from later days' segments, never their ranges,
    /// so it changes at most once more and the cascade still ends.
    private static func around(_ projectDay: BillingProjectDay, settled: Settled) -> Set<BillingProjectDay> {
        after(projectDay, later: settled.later).union(settled.earlier.filter { $0 < projectDay.day }.map {
            BillingProjectDay(projectId: projectDay.projectId, day: $0)
        })
    }

    /// Settles `seeds`, each in its own write transaction (nested in the
    /// caller's when there is one), earliest day first; every day that
    /// changes settles the days after it too. A day only defers to earlier
    /// days and to frozen entries, so a cascade that moves forward from the
    /// earliest seed reaches a fixed point; an earlier day it sends back to
    /// (Ruling 21) depends only on later days' segments, so it settles once
    /// more at most. Returns how many entries changed.
    @discardableResult
    static func settleCascading(_ seeds: Set<BillingProjectDay>, database: any BillingPersistence) throws -> Int {
        var pending = seeds
        var changed = 0
        while let next = pending.min(by: earlier) {
            pending.remove(next)
            let settled = try database.transaction { try settleDay(next, database: database) }
            changed += settled.changed
            if settled.changed > 0 { pending.formUnion(around(next, settled: settled)) }
        }
        return changed
    }

    /// The time an entry owns as its neighbours see it: its recorded ranges,
    /// or, recorded never, its segments' intervals.
    private static func ownedRanges(
        _ stored: StoredBillingEntry, segments: [BillingSegmentDTO]? = nil, database: any BillingPersistence
    ) throws -> [BillingRange] {
        if let ranges = stored.billedRanges { return BillingRange.decode(ranges) }
        if let segments { return BillingRange.intervals(of: segments) }
        return BillingRange.intervals(of: try database.billingSegmentsForEntry(id: stored.entry.id))
    }

    /// The entries listed on other days whose time may overlap `projectDay`'s:
    /// its window is the span of every segment and recorded range of its own
    /// entries — the ranges kept from before, so time a day just gave up is
    /// still in it.
    private static func neighbors(
        of projectDay: BillingProjectDay, stored: [StoredBillingEntry],
        attached: [String: [BillingSegmentDTO]], database: any BillingPersistence
    ) throws -> [StoredBillingEntry] {
        let span = stored.flatMap { item in
            BillingRange.intervals(of: attached[item.entry.id] ?? [])
                + (item.billedRanges.map(BillingRange.decode) ?? [])
        }
        guard let start = span.map(\.start).min(), let end = span.map(\.end).max() else { return [] }
        return try database.billingEntriesOverlapping(
            projectId: projectDay.projectId,
            from: UTCTimestamp.string(epochSeconds: start), until: UTCTimestamp.string(epochSeconds: end)
        ).filter { $0.entry.day != projectDay.day }
    }

    /// `projectDay` and every day listing an entry that overlaps it: what an
    /// entry freezing, reopening, moving or going away there can change.
    private static func neighborhood(
        _ projectDay: BillingProjectDay, database: any BillingPersistence
    ) throws -> Set<BillingProjectDay> {
        let stored = try database.billingEntriesOnDay(projectId: projectDay.projectId, day: projectDay.day)
        var attached: [String: [BillingSegmentDTO]] = [:]
        for item in stored { attached[item.entry.id] = try database.billingSegmentsForEntry(id: item.entry.id) }
        let others = try neighbors(of: projectDay, stored: stored, attached: attached, database: database)
        return Set(others.map { BillingProjectDay(projectId: $0.entry.projectId, day: $0.entry.day) })
            .union([projectDay])
    }

    /// The neighborhood of `entryId`'s day; empty when there is no such entry.
    private static func neighborhood(
        ofEntry entryId: String, database: any BillingPersistence
    ) throws -> Set<BillingProjectDay> {
        guard let entry = try database.billingEntry(id: entryId) else { return [] }
        return try neighborhood(BillingProjectDay(projectId: entry.projectId, day: entry.day), database: database)
    }

    /// What settling one day did: how many entries it wrote, the later days
    /// that defer to it, and the earlier days whose app time it may now
    /// claim (or no longer claims), to settle again.
    struct Settled {
        var changed = 0
        var later: Set<String> = []
        var earlier: Set<String> = []
    }

    /// The Claude-side time an unfrozen entry can hold (Ruling 21): its own
    /// Claude segments', and those of the frozen entries it is heir to — the
    /// root it supplements, or that root's other supplements. Whatever else
    /// it owns is app time, which yields to a Claude claim of any day.
    private static func claudeShield(
        root rootId: String, segments: [BillingSegmentDTO], frozen: [StoredBillingEntry],
        segmentsOf: [String: [BillingSegmentDTO]]
    ) -> [BillingRange] {
        let relatives = frozen.filter { $0.entry.id == rootId || $0.entry.supplementsEntryId == rootId }
        let held = segments + relatives.flatMap { segmentsOf[$0.entry.id] ?? [] }
        return BillingRange.intervals(of: held.filter { !isAppSegment($0) })
    }

    /// The root a new supplement of `entry` would follow, and whose frozen
    /// relatives make up its shield.
    private static func rootId(of entry: BillingEntryDTO) -> String {
        entry.supplementsEntryId ?? entry.id
    }

    /// The order a day grants claims in: oldest first (Rulings 18 and 20);
    /// on a tie a root before its supplements, then the lower rate — as a
    /// number, never the `rate:<cents>` key's text, where 15000 sorted
    /// before 9000 — then by group, and the id only last.
    private static func order(_ entry: BillingEntryDTO) -> (String, Int, Int, String, String) {
        (entry.createdAt, entry.supplementsEntryId == nil ? 0 : 1, entry.rateCents, entry.groupKey, entry.id)
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Decides who bills each second of one project's day, and writes every
    /// entry the rollup still owns to match. The one ownership rule (Rulings
    /// 18, 20, 21 and 22), so that every second bills exactly once, whatever
    /// order it arrived, froze, reopened or moved in, and whichever day each
    /// entry is listed on:
    ///
    /// 1. A **frozen** entry owns exactly its recorded `billed_ranges` — or,
    ///    recorded never, its segments' intervals — and never changes. That
    ///    holds on every day its time overlaps, not only the day it is
    ///    listed on: a run moved to another day keeps its time here.
    /// 2. An **earlier day** comes first for Claude time: what an unfrozen
    ///    entry listed on an earlier day owns of its Claude-side time (a run
    ///    that crossed midnight) is taken here. Its *app* time is not: app
    ///    claims come last across days too (Ruling 21), so this day's Claude
    ///    runs claim it, and the earlier day, settling, yields what any later
    ///    day's open Claude segments hold. Unfrozen entries on later days
    ///    defer to this one, and are returned in `later` to settle again once
    ///    this day changes; earlier days holding app time that this day's
    ///    runs may reach are returned in `earlier`.
    /// 3. An **unfrozen** entry claims its segments' intervals. Time a frozen
    ///    entry's segments hold but that entry does not own (it gave the
    ///    overlap to a run that has since moved, or the run it gave time to
    ///    has reopened) is claimed by its heir: the unfrozen root it
    ///    supplements, listed on this day. With no such heir it is an
    ///    orphan of the root — the entry it supplements, on any day, else
    ///    itself — and goes to that root's open supplement here, else to a
    ///    new one, in the last pass.
    /// 4. Claims are granted minus everything already owned, in two passes:
    ///    every Claude-side claim first (oldest entry first), then every app
    ///    claim — at either granularity, so app time is always the
    ///    **residual** and bills only what no Claude run does. Orphans
    ///    waiting on a supplement come after both passes, so an open
    ///    entry's app claim outranks time a frozen entry gave away (Ruling 22)
    ///    — and the supplement the first settle mints claims nothing ahead of
    ///    it on the next, so settling a day again changes nothing.
    ///
    /// The caller holds the write transaction.
    static func settleDay(_ projectDay: BillingProjectDay, database: any BillingPersistence) throws -> Settled {
        let stored = try database.billingEntriesOnDay(projectId: projectDay.projectId, day: projectDay.day)
        guard !stored.isEmpty else { return Settled() }
        var attached: [String: [BillingSegmentDTO]] = [:]
        for item in stored { attached[item.entry.id] = try database.billingSegmentsForEntry(id: item.entry.id) }
        let byId = Dictionary(stored.map { ($0.entry.id, $0) }, uniquingKeysWith: { first, _ in first })
        let frozen = stored.filter { isFrozen($0.entry) }
        let open = stored.filter { !isFrozen($0.entry) }.sorted { order($0.entry) < order($1.entry) }

        let others = try neighbors(of: projectDay, stored: stored, attached: attached, database: database)
        var segmentsOf = attached
        for item in others { segmentsOf[item.entry.id] = try database.billingSegmentsForEntry(id: item.entry.id) }
        let allFrozen = frozen + others.filter { isFrozen($0.entry) }

        var settled = Settled()
        // Everything owned outside this day's open entries but the earlier
        // days' app time, which this day's own Claude segments may claim.
        var taken: [BillingRange] = []
        var earlierApp: [BillingRange] = []
        // What later days' open runs hold, which this day's app time yields.
        var laterClaude: [BillingRange] = []
        for item in others {
            let segments = segmentsOf[item.entry.id] ?? []
            // An earlier day holding app time — in any entry, frozen or open,
            // root or supplement — is what this day's runs reach into: it
            // yields to them, and takes back what they let go (an orphan of
            // a frozen entry there has no other way to be settled). Settle it
            // again whenever this day changes.
            if item.entry.day < projectDay.day, segments.contains(where: isAppSegment) {
                settled.earlier.insert(item.entry.day)
            }
            if isFrozen(item.entry) {
                taken = BillingRange.union(taken, try ownedRanges(item, segments: segments, database: database))
            } else if item.entry.day < projectDay.day {
                let owned = try ownedRanges(item, segments: segments, database: database)
                let shield = claudeShield(
                    root: rootId(of: item.entry), segments: segments, frozen: allFrozen, segmentsOf: segmentsOf
                )
                let app = BillingRange.subtract(owned, shield)
                taken = BillingRange.union(taken, BillingRange.intersect(owned, shield))
                earlierApp = BillingRange.union(earlierApp, app)
                // App time it owns through a frozen relative's segment.
                if !app.isEmpty { settled.earlier.insert(item.entry.day) }
            } else {
                settled.later.insert(item.entry.day)
                laterClaude = BillingRange.union(
                    laterClaude, BillingRange.intervals(of: segments.filter { !isAppSegment($0) })
                )
            }
        }
        for item in frozen {
            taken = BillingRange.union(
                taken, try ownedRanges(item, segments: attached[item.entry.id] ?? [], database: database)
            )
        }

        // What each open entry claims: its own Claude-side time, the
        // Claude-side time it inherits as heir, and app time, apart.
        var claims: [String: [BillingRange]] = [:]
        var heirClaims: [String: [BillingRange]] = [:]
        var appClaims: [String: [BillingRange]] = [:]
        var sources: [String: [BillingSegmentDTO]] = [:]
        for item in open {
            let segments = attached[item.entry.id] ?? []
            claims[item.entry.id] = BillingRange.intervals(of: segments.filter { !isAppSegment($0) })
            appClaims[item.entry.id] = BillingRange.intervals(of: segments.filter(isAppSegment))
            sources[item.entry.id] = segments
        }
        // Orphans an open root on this day inherits as heir go into the
        // Claude and app passes with its own claims. Every other orphan waits
        // for the last pass, keyed by the root a supplement follows — the one
        // the frozen entry supplements, on whatever day it is listed. An open
        // supplement already holding that root's orphans is *not* their heir
        // here: it is what the last pass minted the first time, and taking
        // the orphan ahead of the app claims would bill the day differently
        // on the second settle than on the first.
        var orphaned: [String: [BillingRange]] = [:]
        var appOrphaned: [String: [BillingRange]] = [:]
        var orphanSources: [String: [BillingSegmentDTO]] = [:]
        var rootEntries: [String: BillingEntryDTO] = [:]
        for item in frozen {
            let segments = attached[item.entry.id] ?? []
            let orphan = BillingRange.subtract(BillingRange.intervals(of: segments), taken)
            guard !orphan.isEmpty else { continue }
            let claudeSide = BillingRange.intersect(
                orphan, BillingRange.intervals(of: segments.filter { !isAppSegment($0) })
            )
            let appSide = BillingRange.subtract(orphan, claudeSide)
            // Only the segments the orphaned time came from describe it.
            let from = segments.filter { !BillingRange.intersect(BillingRange.intervals(of: [$0]), orphan).isEmpty }
            let root = try orphanRoot(of: item.entry, byId: byId, others: others, database: database)
            rootEntries[root.id] = root
            if let heir = byId[root.id], !isFrozen(heir.entry) {
                heirClaims[heir.entry.id] = BillingRange.union(heirClaims[heir.entry.id] ?? [], claudeSide)
                appClaims[heir.entry.id] = BillingRange.union(appClaims[heir.entry.id] ?? [], appSide)
                sources[heir.entry.id, default: []] += from
            } else {
                let rootId = root.id
                orphaned[rootId] = BillingRange.union(orphaned[rootId] ?? [], claudeSide)
                appOrphaned[rootId] = BillingRange.union(appOrphaned[rootId] ?? [], appSide)
                orphanSources[rootId, default: []] += from
            }
        }

        // Open entries' Claude-side claims: an entry's own runs reach into
        // an earlier day's app time (Ruling 21); time it inherits does not,
        // because the earlier day yields only what later runs hold.
        var owns: [String: [BillingRange]] = [:]
        for item in open {
            let own = BillingRange.subtract(claims[item.entry.id] ?? [], taken)
            let inherited = BillingRange.subtract(
                heirClaims[item.entry.id] ?? [], BillingRange.union(taken, earlierApp)
            )
            let granted = BillingRange.union(own, inherited)
            taken = BillingRange.union(taken, granted)
            owns[item.entry.id] = granted
        }
        taken = BillingRange.union(taken, earlierApp)
        // Then app claims, minus what a later day's run holds outside the
        // entry's own Claude-side shield — the part that day takes as app.
        for item in open {
            let shield = claudeShield(
                root: rootId(of: item.entry), segments: attached[item.entry.id] ?? [], frozen: allFrozen,
                segmentsOf: segmentsOf
            )
            let yielded = BillingRange.subtract(laterClaude, shield)
            let granted = BillingRange.subtract(appClaims[item.entry.id] ?? [], BillingRange.union(taken, yielded))
            taken = BillingRange.union(taken, granted)
            owns[item.entry.id] = BillingRange.union(owns[item.entry.id] ?? [], granted)
        }
        // A new supplement's orphans last, after every open entry, app claims
        // included. Ruling 22: the time was given away when its entry froze,
        // so an entry still open that covers it — a reopened app entry, or an
        // app span over a run since re-derived — takes it first. Granting the
        // orphan before app claims would make a reopened app entry bill only
        // the part its frozen run never gave away (900 seconds, not 1800).
        let roots = Set(orphaned.keys).union(appOrphaned.keys).compactMap { rootEntries[$0] }
            .sorted { order($0) < order($1) }.map(\.id)
        var rootOwns: [String: [BillingRange]] = [:]
        for rootId in roots {
            let granted = BillingRange.subtract(orphaned[rootId] ?? [], taken)
            taken = BillingRange.union(taken, granted)
            rootOwns[rootId] = granted
        }
        for rootId in roots {
            let shield = claudeShield(root: rootId, segments: [], frozen: allFrozen, segmentsOf: segmentsOf)
            let yielded = BillingRange.subtract(laterClaude, shield)
            let granted = BillingRange.subtract(appOrphaned[rootId] ?? [], BillingRange.union(taken, yielded))
            taken = BillingRange.union(taken, granted)
            rootOwns[rootId] = BillingRange.union(rootOwns[rootId] ?? [], granted)
        }
        // A root's orphans go to its open supplement on this day — the one an
        // earlier settle minted, or one new time went to — else a new one.
        var mint: [(rootId: String, granted: [BillingRange])] = []
        for rootId in roots {
            guard let granted = rootOwns[rootId], !granted.isEmpty else { continue }
            if let supplement = open.first(where: { $0.entry.supplementsEntryId == rootId }) {
                owns[supplement.entry.id] = BillingRange.union(owns[supplement.entry.id] ?? [], granted)
                sources[supplement.entry.id, default: []] += orphanSources[rootId] ?? []
            } else {
                mint.append((rootId, granted))
            }
        }

        for item in open {
            settled.changed += try write(
                item, owns: owns[item.entry.id] ?? [], attached: attached[item.entry.id] ?? [],
                sources: sources[item.entry.id] ?? [], database: database
            )
        }
        for (rootId, granted) in mint {
            guard let root = rootEntries[rootId] else { continue }
            let supplement = StoredBillingEntry(
                entry: try supplementEntry(of: root, on: projectDay.day, database: database), descriptionEdited: false
            )
            guard try database.upsertBillingEntry(supplement.entry, overwrite: .rollupOwned) else { continue }
            settled.changed += try write(
                supplement, owns: granted, attached: [], sources: orphanSources[rootId] ?? [], database: database
            )
        }
        return settled
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    /// The root a frozen entry's orphans follow: the entry it supplements —
    /// on this day, another day's neighbour, or read by id — else itself. A
    /// supplement's root on another day is still its root: falling back to
    /// the supplement made a supplement of a supplement, rounded on its own.
    private static func orphanRoot(
        of entry: BillingEntryDTO, byId: [String: StoredBillingEntry], others: [StoredBillingEntry],
        database: any BillingPersistence
    ) throws -> BillingEntryDTO {
        guard let rootId = entry.supplementsEntryId else { return entry }
        if let root = byId[rootId]?.entry ?? others.first(where: { $0.entry.id == rootId })?.entry {
            return root
        }
        return try database.billingEntry(id: rootId) ?? entry
    }

    /// A new, empty supplement of `root` on `day` for orphaned time. Its rate
    /// and key are the root's slot; everything else is the project's terms
    /// now, as `compose` writes them — the root's are the terms it was
    /// billed under, not the terms new time bills under.
    private static func supplementEntry(
        of root: BillingEntryDTO, on day: String, database: any BillingPersistence
    ) throws -> BillingEntryDTO {
        let project = try database.billingProject(id: root.projectId)
        let global = try BillingPrefs.snapshot(database).currency
        let currency = try currencyCode(for: project, fallback: global, database: database)
        let now = UTCTimestamp.now()
        return BillingEntryDTO(
            id: UUID().uuidString, projectId: root.projectId, clientId: project?.clientId, day: day,
            groupKey: root.groupKey, startedAt: "", endedAt: "", rawSeconds: 0, billedSeconds: 0,
            rateCents: root.rateCents, currency: currency, amountCents: 0,
            roundingMinutes: project?.roundingMinutes ?? 15, roundingMode: project?.roundingMode ?? "up",
            status: BillingStatus.unbilled.rawValue, description: "", origin: "auto", locked: false,
            supplementsEntryId: root.id, createdAt: now, updatedAt: now
        )
    }

    /// Writes one unfrozen entry as owning `owns`, or removes it when it owns
    /// nothing, holds no segment, no supplement points at it and its words
    /// were never typed by hand. Returns whether anything changed.
    private static func write(
        _ stored: StoredBillingEntry, owns: [BillingRange], attached: [BillingSegmentDTO],
        sources: [BillingSegmentDTO], database: any BillingPersistence
    ) throws -> Int {
        let entry = stored.entry
        if owns.isEmpty, attached.isEmpty, !stored.descriptionEdited,
           try database.deleteEmptyBillingEntry(id: entry.id) {
            return 1
        }
        // A segment whose start does not parse cannot be placed in time, so
        // its seconds are billed as they are.
        let loose = attached.filter { UTCTimestamp.epochSeconds($0.startedAt) == nil }
            .reduce(0) { $0 + max(0, $1.seconds) }
        let raw = BillingRange.measure(owns) + loose
        // Once, over the union total. Rounding each segment first is how five
        // five-minute checks become 75 billed minutes.
        let billed = BillingRounding.billedSeconds(
            rawSeconds: raw, roundingMinutes: entry.roundingMinutes, mode: entry.roundingMode
        )
        // Everything it holds and everything it owns — an heir's inherited
        // time included. The latest *end*, not the end of the segment that
        // starts last: parallel sessions overlap, and a short one starting
        // late would otherwise cut the entry's end hours early.
        let starts = attached.map(\.startedAt) + owns.map { UTCTimestamp.string(epochSeconds: $0.start) }
        let ends = attached.map(\.endedAt) + owns.map { UTCTimestamp.string(epochSeconds: $0.end) }
        let bounds = (starts.min() ?? entry.startedAt, ends.max() ?? entry.endedAt)
        let computed = Figures(
            startedAt: bounds.0, endedAt: bounds.1, raw: raw, billed: billed,
            amount: amountCents(billedSeconds: billed, rateCents: entry.rateCents)
        )
        let description = stored.descriptionEdited
            ? entry.description
            : try describe(segments: sources, previous: entry.description, database: database)
        let ranges = BillingRange.encode(owns)
        let current = Figures(
            startedAt: entry.startedAt, endedAt: entry.endedAt, raw: entry.rawSeconds,
            billed: entry.billedSeconds, amount: entry.amountCents
        )
        guard current != computed || entry.description != description || stored.billedRanges != ranges
        else { return 0 }
        guard try database.upsertBillingEntry(
            rewritten(entry, figures: computed, description: description), overwrite: .rollupOwned
        ) else { return 0 }
        try database.setBillingEntryBilledRanges(id: entry.id, ranges: ranges)
        return 1
    }

    /// An entry's figures — what `settleDay` compares and writes.
    private struct Figures: Equatable {
        let startedAt: String
        let endedAt: String
        let raw: Int
        let billed: Int
        let amount: Int
    }

    /// Currency lives on the client — a client is billed in one currency and
    /// every project under them inherits it. No client means the global
    /// setting, `fallback`.
    private static func currencyCode(
        for project: BillingProjectDTO?,
        fallback: String,
        database: any BillingPersistence
    ) throws -> String {
        guard let clientId = project?.clientId, !clientId.isEmpty,
              let client = try database.billingClient(id: clientId),
              !client.currency.isEmpty else {
            return fallback
        }
        return client.currency
    }

    /// What makes an entry defensible three months later: the titles of the
    /// sessions the time came from, the notes typed on its timers, and the
    /// branches they ran on. A generic time tracker cannot write this line,
    /// because it never saw the work.
    ///
    /// The titles come from rows retention deletes: a session's transcript
    /// title, an app span's name. A recompute after they are gone would
    /// rebuild the line without them and blank a description the client may
    /// already have seen. So while any of the entry's segments has nothing to
    /// title it by, the entry's `previous` description is kept as it is.
    private static func describe(
        segments: [BillingSegmentDTO], previous: String?, database: any BillingPersistence
    ) throws -> String {
        var sessionIds: [String] = []
        var notes: [String] = []
        var branches: [String] = []
        for segment in segments {
            if !segment.sessionId.isEmpty, !sessionIds.contains(segment.sessionId) {
                sessionIds.append(segment.sessionId)
            }
            let note = segment.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty, !notes.contains(note) { notes.append(note) }
            if !segment.branch.isEmpty, !branches.contains(segment.branch) {
                branches.append(segment.branch)
            }
        }

        let titled = try database.billingSessionTitles(sessionIds: sessionIds)
        if let previous, !previous.isEmpty, !titled.missing.isEmpty { return previous }
        var parts = titled.titles
        parts.append(contentsOf: notes)
        if !branches.isEmpty { parts.append("on \(branches.joined(separator: ", "))") }
        return parts.joined(separator: "; ")
    }

    // MARK: - Recompute

    /// Re-settles the days of every entry (or only of `only`), bringing each
    /// entry the rollup owns back in line with the time it now owns, and
    /// removing one left with nothing. Returns how many changed.
    ///
    /// The roll only ever *adds* segments. Re-derivation detaches them (a
    /// cutoff change reshapes runs, a repo is re-mapped to another project, a
    /// run reopens), and without this the entry kept its old figures — while
    /// the same time rolled again into its new slot. That was double billing.
    /// The entry's own snapshotted rate and rounding are used, never the live
    /// settings: recomputing is about *which time*, not *what price*.
    @discardableResult
    public static func recomputeOwnedEntries(database: any BillingPersistence, only: Set<String>? = nil) throws -> Int {
        let days = try only.map { try projectDays(of: $0, database: database) } ?? Set(try database.billingEntryDays())
        return try settleCascading(days, database: database)
    }

    // MARK: - Money

    /// `billedSeconds` at `rateCents` per hour, in whole cents, rounded half-up.
    ///
    /// Delegates to `Money.amountCents`, the one formula the app's reprice
    /// path also uses, so the daemon's figure and the editor's figure can
    /// never disagree by a cent.
    public static func amountCents(billedSeconds: Int, rateCents: Int) -> Int {
        Money.amountCents(seconds: billedSeconds, rateCents: rateCents)
    }

    // MARK: - Editing

    /// A hand edit.
    ///
    /// - A **new** entry, or an edit that changes a **figure** (project, day,
    ///   times, hours, rate, currency, amount, rounding), lands as
    ///   `origin: "user"`. That freezes it against the rollup: the next pass
    ///   neither recomputes the figure the user just chose nor grows it — later
    ///   work that day goes to a supplement.
    /// - An edit that changes **only the description** keeps the entry's
    ///   origin, so an auto entry goes on tracking its time; the words are
    ///   remembered (`description_edited`) and kept through every recompute.
    /// - **Status never changes here.** `setStatus` is the one path, because it
    ///   is the one that writes the audit row. A save that would move status is
    ///   refused rather than silently applied or silently ignored.
    /// - **A stale save is refused.** The editor sends the whole row it last
    ///   read; if the rollup has written the entry since (its `updated_at` or
    ///   tracked seconds moved), writing those figures would drop the time the
    ///   rollup just attached and freeze the entry without it.
    @discardableResult
    public static func saveEntry(_ dto: BillingEntryDTO, database: any BillingPersistence) throws -> BillingEntryDTO {
        // A figure edit freezes the entry at the ranges it owns, so they must
        // be current: segments re-derived since the last roll would otherwise
        // leave it owning time that is gone. Settled in its own transaction
        // first, so a save refused below as stale leaves the fresh figures
        // for the editor to reload. Not again under the save's write lock: a
        // pass that commits in between moves `updated_at`, and the stale
        // check below refuses the save rather than freezing old figures.
        if !dto.id.isEmpty {
            try settleCascading(try neighborhood(ofEntry: dto.id, database: database), database: database)
        }
        return try database.transaction {
            var seeds = dto.id.isEmpty ? [] : try neighborhood(ofEntry: dto.id, database: database)
            let existing = dto.id.isEmpty ? nil : try database.billingEntry(id: dto.id)
            // Settling removes an entry left owning and holding nothing (its
            // time was re-derived away). Saving the editor's stale copy would
            // bring it back as a hand-made entry billing time that is gone.
            if !dto.id.isEmpty, existing == nil { throw RollupError.unknownEntry(dto.id) }
            if let existing, existing.locked { throw RollupError.entryIsLocked(dto.id) }
            let currentStatus = existing?.status ?? BillingStatus.unbilled.rawValue
            guard dto.status == currentStatus else {
                throw RollupError.statusChangeNotAllowed(current: currentStatus, requested: dto.status)
            }
            if let existing, existing.updatedAt != dto.updatedAt || existing.rawSeconds != dto.rawSeconds {
                throw RollupError.entryChanged(dto.id)
            }

            let figuresChanged = existing.map { old in
                old.projectId != dto.projectId || old.day != dto.day
                    || old.startedAt != dto.startedAt || old.endedAt != dto.endedAt
                    || old.rawSeconds != dto.rawSeconds || old.billedSeconds != dto.billedSeconds
                    || old.rateCents != dto.rateCents || old.currency != dto.currency
                    || old.amountCents != dto.amountCents
                    || old.roundingMinutes != dto.roundingMinutes || old.roundingMode != dto.roundingMode
            } ?? true
            let descriptionChanged = existing.map { $0.description != dto.description } ?? false

            let now = UTCTimestamp.now()
            let entry = BillingEntryDTO(
                id: existing?.id ?? (dto.id.isEmpty ? UUID().uuidString : dto.id),
                projectId: dto.projectId,
                clientId: dto.clientId,
                day: dto.day,
                groupKey: dto.groupKey,
                startedAt: dto.startedAt,
                endedAt: dto.endedAt,
                rawSeconds: dto.rawSeconds,
                billedSeconds: dto.billedSeconds,
                rateCents: dto.rateCents,
                currency: dto.currency,
                amountCents: dto.amountCents,
                roundingMinutes: dto.roundingMinutes,
                roundingMode: dto.roundingMode,
                status: currentStatus,
                description: dto.description,
                origin: figuresChanged ? "user" : (existing?.origin ?? "user"),
                locked: false,
                supplementsEntryId: dto.supplementsEntryId,
                createdAt: existing?.createdAt ?? now,
                updatedAt: now
            )
            guard try database.upsertBillingEntry(entry, overwrite: .unlocked) else {
                throw RollupError.entryIsLocked(entry.id)
            }
            if descriptionChanged { try database.markBillingEntryDescriptionEdited(id: entry.id) }
            // A figure edit freezes the entry at the ranges it owned; a moved
            // entry takes them to its new day. Both days, and every day
            // overlapping either, are settled again.
            seeds.formUnion(try neighborhood(
                BillingProjectDay(projectId: entry.projectId, day: entry.day), database: database
            ))
            try settleCascading(seeds, database: database)
            return try database.billingEntry(id: entry.id) ?? entry
        }
    }

    /// Changes an entry's description and nothing else.
    ///
    /// The editor's path for the words. It sends the one field it changed, not
    /// a copy of the row: today's auto entry grows every pass, so a whole-row
    /// save from a window opened a minute ago carries stale figures. Here the
    /// figures are never written, so the entry stays the rollup's to maintain;
    /// `description_edited` keeps the words through every recompute.
    @discardableResult
    public static func setDescription(
        entryId: String, description: String, database: any BillingPersistence
    ) throws -> BillingEntryDTO {
        try database.transaction {
            guard let existing = try database.billingEntry(id: entryId) else {
                throw RollupError.unknownEntry(entryId)
            }
            guard !existing.locked else { throw RollupError.entryIsLocked(entryId) }
            let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
            // The SQL re-checks `locked = 0`; a refused write is a refusal,
            // never the unchanged row passed off as success.
            guard try database.setBillingEntryDescription(id: entryId, description: text, at: UTCTimestamp.now())
            else { throw RollupError.entryIsLocked(entryId) }
            guard let stored = try database.billingEntry(id: entryId) else {
                throw RollupError.unknownEntry(entryId)
            }
            return stored
        }
    }

    public static func deleteEntry(id: String, database: any BillingPersistence) throws {
        try database.transaction {
            guard let existing = try database.billingEntry(id: id) else {
                throw RollupError.unknownEntry(id)
            }
            guard !existing.locked else { throw RollupError.entryIsLocked(id) }
            // Its supplements go with it, so a billed one would take invoiced
            // time out of the totals and free it to be billed again.
            let frozen = try database.billingFrozenSupplementCount(of: id)
            guard frozen == 0 else { throw RollupError.entryHasFrozenSupplements(id: id, count: frozen) }
            let seeds = try neighborhood(
                BillingProjectDay(projectId: existing.projectId, day: existing.day), database: database
            )
            try database.deleteBillingEntry(id: id)
            // Its segments re-roll on the next pass; what it owned is free
            // again now, for the entries on its day and every day it overlaps.
            try settleCascading(seeds, database: database)
        }
    }

    /// The only way an entry's status ever changes. Every move is audited,
    /// including moves backwards — reopening a billed day is allowed, because
    /// mistakes happen, but it leaves a mark.
    @discardableResult
    public static func setStatus(
        entryId: String, to status: BillingStatus, source: String, database: any BillingPersistence
    ) throws -> BillingEntryDTO {
        // Freezing keeps the ranges the entry owns at that moment, so the day
        // is settled first (see `saveEntry`). An entry that settling removes
        // owned nothing and held nothing: it is reported unknown.
        try settleCascading(try neighborhood(ofEntry: entryId, database: database), database: database)
        // Read and write under one write lock, so the row written is the row
        // as it is now — never a snapshot a rollup pass has since grown.
        return try database.transaction {
            var seeds = try neighborhood(ofEntry: entryId, database: database)
            guard let existing = try database.billingEntry(id: entryId) else {
                throw RollupError.unknownEntry(entryId)
            }
            guard existing.status != status.rawValue else { return existing }

            let updated = BillingEntryDTO(
                id: existing.id,
                projectId: existing.projectId,
                clientId: existing.clientId,
                day: existing.day,
                groupKey: existing.groupKey,
                startedAt: existing.startedAt,
                endedAt: existing.endedAt,
                rawSeconds: existing.rawSeconds,
                billedSeconds: existing.billedSeconds,
                rateCents: existing.rateCents,
                currency: existing.currency,
                amountCents: existing.amountCents,
                roundingMinutes: existing.roundingMinutes,
                roundingMode: existing.roundingMode,
                status: status.rawValue,
                description: existing.description,
                origin: existing.origin,
                locked: status.locksTheEntry,
                supplementsEntryId: existing.supplementsEntryId,
                createdAt: existing.createdAt,
                updatedAt: UTCTimestamp.now()
            )
            try database.upsertBillingEntry(updated, overwrite: .any)
            try database.appendBillingAudit(
                entryId: entryId, field: "status",
                oldValue: existing.status, newValue: status.rawValue, source: source
            )
            // A reopened entry is unfrozen again: it and every unfrozen entry
            // on its day, or on a day it overlaps, are settled against what
            // is frozen now.
            seeds.formUnion(try neighborhood(ofEntry: entryId, database: database))
            try settleCascading(seeds, database: database)
            return try database.billingEntry(id: entryId) ?? updated
        }
    }

    /// Moves orphaned segments into a project. Returns how many moved.
    @discardableResult
    public static func assignSegments(
        ids: [String], projectId: String?, database: any BillingPersistence
    ) throws -> Int {
        try database.assignSegments(ids: ids, toProject: projectId)
    }

    /// Moves every unassigned, unbilled segment from `projectRoot` into the
    /// project and rolls the finished ones into entries. The daemon's own
    /// list, not the page of recent runs a window holds, so older runs from
    /// the repository are billed too. Returns how many moved.
    @discardableResult
    public static func assignRepository(
        projectRoot: String, projectId: String, options: BillingRollupOptions, database: any BillingPersistence
    ) throws -> Int {
        guard !projectRoot.isEmpty else { return 0 }
        let ids = try database.unassignedSegmentIDs(projectRoot: projectRoot)
        let moved = try database.assignSegments(ids: ids, toProject: projectId)
        try promoteSegments(ids: ids, options: options, database: database)
        return moved
    }

    // MARK: - Overview

    /// One row per currency, never a cross-currency sum. The top-level figures
    /// are the most-used currency's row (see `BillingOverviewDTO`).
    public static func overview(database: any BillingPersistence) throws -> BillingOverviewDTO {
        let empty = BillingOverviewBucketDTO(seconds: 0, amountCents: 0, entryCount: 0)
        let rows = try database.billingOverviewBuckets().map { group in
            BillingOverviewCurrencyDTO(
                currency: group.currency,
                unbilled: group.buckets[BillingStatus.unbilled.rawValue] ?? empty,
                billed: group.buckets[BillingStatus.billed.rawValue] ?? empty,
                paid: group.buckets[BillingStatus.paid.rawValue] ?? empty
            )
        }
        return BillingOverviewDTO(
            unbilled: rows.first?.unbilled ?? empty,
            billed: rows.first?.billed ?? empty,
            paid: rows.first?.paid ?? empty,
            currency: rows.first?.currency ?? "USD",
            byCurrency: rows
        )
    }
}

/// A half-open interval of wall-clock time, `[start, end)` in epoch seconds —
/// the unit billing ownership is decided in. Lists of them are kept
/// normalized: sorted, non-empty and non-overlapping. One `ActivityRuns`
/// span, so the interval algebra has one copy.
public typealias BillingRange = ActivityRuns.Span<Int>

extension ActivityRuns.Span where Stamp == Int {

    /// Sorted, with empty ranges dropped and touching or overlapping ones merged.
    public static func normalized(_ ranges: [BillingRange]) -> [BillingRange] {
        ActivityRuns.union(ranges.filter { $0.end > $0.start })
    }

    /// The time `segments` cover. A segment whose start does not parse has no
    /// place in time and is left out.
    public static func intervals(of segments: [BillingSegmentDTO]) -> [BillingRange] {
        normalized(segments.compactMap { segment in
            UTCTimestamp.epochSeconds(segment.startedAt).map {
                BillingRange(start: $0, end: $0 + max(0, segment.seconds))
            }
        })
    }

    public static func union(_ lhs: [BillingRange], _ rhs: [BillingRange]) -> [BillingRange] {
        normalized(lhs + rhs)
    }

    /// `lhs` with every second of `rhs` taken out.
    public static func subtract(_ lhs: [BillingRange], _ rhs: [BillingRange]) -> [BillingRange] {
        ActivityRuns.subtract(lhs, rhs)
    }

    /// Every second in both `lhs` and `rhs`.
    public static func intersect(_ lhs: [BillingRange], _ rhs: [BillingRange]) -> [BillingRange] {
        ActivityRuns.intersect(lhs, rhs)
    }

    /// Seconds covered, overlaps counted once.
    public static func measure(_ ranges: [BillingRange]) -> Int {
        ActivityRuns.unionLength(normalized(ranges))
    }

    /// `start-end` pairs joined by `;`; `""` for none.
    public static func encode(_ ranges: [BillingRange]) -> String {
        normalized(ranges).map { "\($0.start)-\($0.end)" }.joined(separator: ";")
    }

    public static func decode(_ text: String) -> [BillingRange] {
        normalized(text.split(separator: ";").compactMap { pair in
            let bounds = pair.split(separator: "-").compactMap { Int($0) }
            guard bounds.count == 2 else { return nil }
            return BillingRange(start: bounds[0], end: bounds[1])
        })
    }
}
