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
/// entries own what they recorded, Claude-side entries own the rest of their
/// runs, and app entries own the residual — so every second of the day's
/// time bills exactly once.
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
    /// look at again — every one, or only those of `recomputing` when the
    /// caller knows which entries its derivation can have touched
    /// (`BillingTask`). Returns the number of entries created, recomputed or
    /// removed — zero is the normal steady state.
    @discardableResult
    public static func run(
        options: BillingRollupOptions, database: any BillingPersistence, recomputing: Set<String>? = nil
    ) throws -> Int {
        let rolled = try roll(try database.billingRollupCandidates(ids: nil), options: options, database: database)
        let days = try recomputing.map { try projectDays(of: $0, database: database) }
            ?? Set(try database.billingEntryDays())
        return rolled.count + (try settle(days.subtracting(rolled.days), database: database))
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
        var dayOrder: [BillingProjectDay] = []
        var slotsByDay: [BillingProjectDay: [Slot]] = [:]
        for slot in order {
            if slotsByDay[slot.projectDay] == nil { dayOrder.append(slot.projectDay) }
            slotsByDay[slot.projectDay, default: []].append(slot)
        }
        var rolled = Rolled()
        for projectDay in dayOrder {
            try database.transaction {
                var attached = 0
                for slot in slotsByDay[projectDay] ?? [] where try attach(
                    grouped[slot] ?? [], to: slot, project: projects[slot.projectId] ?? nil,
                    options: options, database: database
                ) {
                    attached += 1
                }
                guard attached > 0 else { return }
                rolled.count += try settleDay(projectDay, database: database)
                rolled.days.insert(projectDay)
            }
        }
        return rolled
    }

    /// The day-granularity key for time billed at `rateCents`.
    public static func dayGroupKey(rateCents: Int) -> String { "rate:\(rateCents)" }

    /// Attaches one group's segments to the entry that should hold them,
    /// creating it if there is none. The figures are `settleDay`'s, written
    /// right after in the same transaction. Returns whether anything attached.
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
    ) throws -> Bool {
        // Still unattached, still billable, still where they were grouped:
        // another writer may have rolled, re-derived or reassigned them, or
        // deleted the project, since the candidate read.
        let grouped = Dictionary(segments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let fresh = try database.billingRollupCandidates(ids: segments.map(\.id)).filter { segment in
            guard let original = grouped[segment.id] else { return false }
            return segment.projectId == slot.projectId && segment.repoId == original.repoId
                && segment.startedAt == original.startedAt && segment.tz == original.tz
        }
        guard !fresh.isEmpty else { return false }

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
        if let target {
            entryId = target.entry.id
            // A legacy `''` day entry is re-keyed the first time it takes time.
            if target.entry.supplementsEntryId == nil, target.entry.groupKey != slot.groupKey {
                guard try database.upsertBillingEntry(
                    rewritten(target.entry, groupKey: slot.groupKey), overwrite: .rollupOwned
                ) else { return false }
            }
        } else {
            let entry = try compose(
                slot: slot, supplements: supplements, project: project, options: options, database: database
            )
            // The entry row goes in first: a segment may only point at an
            // entry that exists.
            guard try database.upsertBillingEntry(entry, overwrite: .rollupOwned) else { return false }
            entryId = entry.id
        }
        try database.attachSegments(ids: fresh.map(\.id), toEntry: entryId)
        return true
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
            currency: try currencyCode(for: project, options: options, database: database),
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

    /// Settles the day of `entryId`'s entry, if it exists, in its own write
    /// transaction.
    private static func settleDay(ofEntry entryId: String, database: any BillingPersistence) throws {
        try database.transaction { try settleDayInTransaction(ofEntry: entryId, database: database) }
    }

    /// The same, for a caller already holding the write transaction.
    private static func settleDayInTransaction(ofEntry entryId: String, database: any BillingPersistence) throws {
        guard let entry = try database.billingEntry(id: entryId) else { return }
        try settleDay(BillingProjectDay(projectId: entry.projectId, day: entry.day), database: database)
    }

    /// Settles each day in its own write transaction, in a stable order.
    private static func settle(_ days: Set<BillingProjectDay>, database: any BillingPersistence) throws -> Int {
        var changed = 0
        for projectDay in days.sorted(by: { ($0.projectId, $0.day) < ($1.projectId, $1.day) }) {
            try database.transaction { changed += try settleDay(projectDay, database: database) }
        }
        return changed
    }

    /// Decides who bills each second of one project's day, and writes every
    /// entry the rollup still owns to match. The one ownership rule (Ruling
    /// 18), so that every second of the day's time bills exactly once,
    /// whatever order it arrived, froze, reopened or moved in:
    ///
    /// 1. A **frozen** entry owns exactly its recorded `billed_ranges` — or,
    ///    recorded never, its segments' intervals — and never changes.
    /// 2. An **unfrozen** entry claims its segments' intervals. Time a frozen
    ///    entry's segments hold but that entry does not own (it gave the
    ///    overlap to a run that has since moved, or the run it gave time to
    ///    has reopened) is claimed by its heir: the unfrozen root it
    ///    supplements, else that root's open supplement.
    /// 3. Claims are granted minus everything already owned: the frozen
    ///    ranges first, then the Claude-side entries oldest first, then the
    ///    app entries, which are therefore the **residual** — app time bills
    ///    only what no Claude run does.
    /// 4. Orphaned time with no heir gets a new supplement of its root.
    ///
    /// The caller holds the write transaction. Returns how many entries were
    /// written, created or removed.
    @discardableResult
    static func settleDay(_ projectDay: BillingProjectDay, database: any BillingPersistence) throws -> Int {
        let stored = try database.billingEntriesOnDay(projectId: projectDay.projectId, day: projectDay.day)
        guard !stored.isEmpty else { return 0 }
        var attached: [String: [BillingSegmentDTO]] = [:]
        for item in stored { attached[item.entry.id] = try database.billingSegmentsForEntry(id: item.entry.id) }
        let byId = Dictionary(stored.map { ($0.entry.id, $0) }, uniquingKeysWith: { first, _ in first })
        let frozen = stored.filter { isFrozen($0.entry) }
        let open = stored.filter { !isFrozen($0.entry) }.sorted { lhs, rhs in
            let left = (isAppGroupKey(lhs.entry.groupKey) ? 1 : 0, lhs.entry.createdAt, lhs.entry.id)
            let right = (isAppGroupKey(rhs.entry.groupKey) ? 1 : 0, rhs.entry.createdAt, rhs.entry.id)
            return left < right
        }

        var taken: [BillingRange] = []
        for item in frozen {
            let ranges = item.billedRanges.map(BillingRange.decode)
                ?? BillingRange.intervals(of: attached[item.entry.id] ?? [])
            taken = BillingRange.union(taken, ranges)
        }

        var claims: [String: [BillingRange]] = [:]
        var sources: [String: [BillingSegmentDTO]] = [:]
        for item in open {
            claims[item.entry.id] = BillingRange.intervals(of: attached[item.entry.id] ?? [])
            sources[item.entry.id] = attached[item.entry.id] ?? []
        }
        // Orphans with no heir yet, by the root a new supplement would follow.
        var orphaned: [String: [BillingRange]] = [:]
        var orphanSources: [String: [BillingSegmentDTO]] = [:]
        for item in frozen {
            let segments = attached[item.entry.id] ?? []
            let orphan = BillingRange.subtract(BillingRange.intervals(of: segments), taken)
            guard !orphan.isEmpty else { continue }
            let rootId = item.entry.supplementsEntryId.flatMap { byId[$0] == nil ? nil : $0 } ?? item.entry.id
            let heir = byId[rootId].flatMap { isFrozen($0.entry) ? nil : $0 }
                ?? open.first { $0.entry.supplementsEntryId == rootId }
            if let heir {
                claims[heir.entry.id] = BillingRange.union(claims[heir.entry.id] ?? [], orphan)
                sources[heir.entry.id, default: []] += segments
            } else {
                orphaned[rootId] = BillingRange.union(orphaned[rootId] ?? [], orphan)
                orphanSources[rootId, default: []] += segments
            }
        }

        var changed = 0
        for item in open {
            let owns = BillingRange.subtract(claims[item.entry.id] ?? [], taken)
            taken = BillingRange.union(taken, owns)
            changed += try write(item, owns: owns, attached: attached[item.entry.id] ?? [],
                                 sources: sources[item.entry.id] ?? [], database: database)
        }
        for rootId in orphaned.keys.sorted() {
            guard let root = byId[rootId] else { continue }
            let owns = BillingRange.subtract(orphaned[rootId] ?? [], taken)
            guard !owns.isEmpty else { continue }
            taken = BillingRange.union(taken, owns)
            let now = UTCTimestamp.now()
            let entry = root.entry
            let supplement = StoredBillingEntry(entry: BillingEntryDTO(
                id: UUID().uuidString, projectId: entry.projectId, clientId: entry.clientId, day: entry.day,
                groupKey: entry.groupKey, startedAt: "", endedAt: "", rawSeconds: 0, billedSeconds: 0,
                rateCents: entry.rateCents, currency: entry.currency, amountCents: 0,
                roundingMinutes: entry.roundingMinutes, roundingMode: entry.roundingMode,
                status: BillingStatus.unbilled.rawValue, description: "", origin: "auto", locked: false,
                supplementsEntryId: entry.id, createdAt: now, updatedAt: now
            ), descriptionEdited: false)
            guard try database.upsertBillingEntry(supplement.entry, overwrite: .rollupOwned) else { continue }
            changed += try write(supplement, owns: owns, attached: [], sources: orphanSources[rootId] ?? [],
                                 database: database)
        }
        return changed
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
        let bounds = attached.isEmpty
            ? (owns.first.map { UTCTimestamp.string(epochSeconds: $0.start) } ?? entry.startedAt,
               owns.last.map { UTCTimestamp.string(epochSeconds: $0.end) } ?? entry.endedAt)
            // The latest *end*, not the end of the segment that starts last:
            // parallel sessions overlap, and a short one starting late would
            // otherwise cut the entry's end hours early.
            : (attached.map(\.startedAt).min() ?? "", attached.map(\.endedAt).max() ?? "")
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

    /// Wall-clock seconds the segments cover: their union, so overlapping
    /// time from parallel sessions or an app is counted once. With `covered`,
    /// only the part of that union outside `covered`. A segment whose start
    /// does not parse cannot be placed, so its seconds are added as they are.
    public static func rawSeconds(
        of segments: [BillingSegmentDTO], excluding covered: [BillingSegmentDTO] = []
    ) -> Int {
        let loose = segments.filter { UTCTimestamp.epochSeconds($0.startedAt) == nil }
            .reduce(0) { $0 + max(0, $1.seconds) }
        let owns = BillingRange.subtract(BillingRange.intervals(of: segments), BillingRange.intervals(of: covered))
        return BillingRange.measure(owns) + loose
    }

    /// Currency lives on the client — a client is billed in one currency and
    /// every project under them inherits it. No client means the global
    /// setting.
    private static func currencyCode(
        for project: BillingProjectDTO?,
        options: BillingRollupOptions,
        database: any BillingPersistence
    ) throws -> String {
        guard let clientId = project?.clientId, !clientId.isEmpty,
              let client = try database.billingClient(id: clientId),
              !client.currency.isEmpty else {
            return options.currency
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

        if let previous, !previous.isEmpty,
           !(try database.billingUntitledSessionIds(sessionIds: sessionIds)).isEmpty {
            return previous
        }
        var parts = try database.billingSessionTitles(sessionIds: sessionIds)
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
        return try settle(days, database: database)
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
        // for the editor to reload; and again under the save's write lock.
        if !dto.id.isEmpty { try settleDay(ofEntry: dto.id, database: database) }
        var saved: BillingEntryDTO?
        try database.transaction {
            if !dto.id.isEmpty { try settleDayInTransaction(ofEntry: dto.id, database: database) }
            let existing = dto.id.isEmpty ? nil : try database.billingEntry(id: dto.id)
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
            // entry takes them to its new day. Both days are settled again.
            var days: Set<BillingProjectDay> = [BillingProjectDay(projectId: entry.projectId, day: entry.day)]
            if let existing { days.insert(BillingProjectDay(projectId: existing.projectId, day: existing.day)) }
            for projectDay in days.sorted(by: { ($0.projectId, $0.day) < ($1.projectId, $1.day) }) {
                try settleDay(projectDay, database: database)
            }
            saved = try database.billingEntry(id: entry.id) ?? entry
        }
        guard let saved else { throw RollupError.unknownEntry(dto.id) }
        return saved
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
        var stored: BillingEntryDTO?
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
            stored = try database.billingEntry(id: entryId)
        }
        guard let stored else { throw RollupError.unknownEntry(entryId) }
        return stored
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
            try database.deleteBillingEntry(id: id)
            // Its segments re-roll on the next pass; what it owned is free
            // again now, for the entries still on its day.
            try settleDay(BillingProjectDay(projectId: existing.projectId, day: existing.day), database: database)
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
        try settleDay(ofEntry: entryId, database: database)
        var result: BillingEntryDTO?
        // Read and write under one write lock, so the row written is the row
        // as it is now — never a snapshot a rollup pass has since grown.
        try database.transaction {
            try settleDayInTransaction(ofEntry: entryId, database: database)
            guard let existing = try database.billingEntry(id: entryId) else {
                throw RollupError.unknownEntry(entryId)
            }
            guard existing.status != status.rawValue else {
                result = existing
                return
            }

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
            // A reopened entry is unfrozen again: it and every other unfrozen
            // entry on its day are settled against what is frozen now.
            try settleDay(BillingProjectDay(projectId: existing.projectId, day: existing.day), database: database)
            result = try database.billingEntry(id: entryId) ?? updated
        }
        guard let result else { throw RollupError.unknownEntry(entryId) }
        return result
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
/// normalized: sorted, non-empty and non-overlapping.
public struct BillingRange: Sendable, Equatable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }

    /// Sorted, with empty ranges dropped and touching or overlapping ones merged.
    public static func normalized(_ ranges: [BillingRange]) -> [BillingRange] {
        var merged: [BillingRange] = []
        for range in ranges.filter({ $0.end > $0.start }).sorted(by: { $0.start < $1.start }) {
            if let last = merged.last, range.start <= last.end {
                merged[merged.count - 1] = BillingRange(start: last.start, end: max(last.end, range.end))
            } else {
                merged.append(range)
            }
        }
        return merged
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
        let holes = normalized(rhs)
        var pieces: [BillingRange] = []
        for range in normalized(lhs) {
            var cursor = range.start
            for hole in holes where hole.end > cursor && hole.start < range.end {
                if hole.start > cursor { pieces.append(BillingRange(start: cursor, end: hole.start)) }
                cursor = max(cursor, hole.end)
            }
            if cursor < range.end { pieces.append(BillingRange(start: cursor, end: range.end)) }
        }
        return pieces
    }

    /// Seconds covered, overlaps counted once.
    public static func measure(_ ranges: [BillingRange]) -> Int {
        normalized(ranges).reduce(0) { $0 + $1.end - $1.start }
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
