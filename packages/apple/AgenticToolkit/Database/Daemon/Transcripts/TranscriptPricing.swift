#if canImport(AgenticToolkitCore)
import Foundation

/// Per-million-token pricing for Claude models, used by the JSONL importer to
/// compute per-session cost and by `/insights/cache-misses` to price the tokens
/// a cache miss forced back through the cache.
///
/// **This file is the canonical pricing source for the daemons.** It once
/// mirrored a `PRICING` table in the deployed CSL status line
/// (`.../references/statusline/base_info.py`); that table is gone and this is
/// the only one left. The upstream authority is Anthropic's `claude-api` skill
/// (`shared/models.md` and `shared/prompt-caching.md`) — check prices there, not
/// from memory, when adding a model.
///
/// Matching strategy: exact model id, then the id with a trailing `-YYYYMMDD`
/// release date stripped (transcripts carry the dated form — see
/// ``canonicalModelID(_:)``), then a family keyword. Unknown models return
/// `nil` → zero cost.
///
/// The keyword fallback is a *guess for a model this table has never heard of*,
/// and it guesses at the family's current generation — so an id that ships
/// before this table is updated is costed at today's rate rather than a retired
/// one. It must never be how a model we do know about gets priced: that is what
/// the date-stripping step is for. `testCostCalculationPricesEveryModelSeenInCapture`
/// holds that line for every id in the capture.
public enum TranscriptPricing {

    /// Bumped whenever ``table``, the fallbacks, or the cost formula change.
    ///
    /// `session_metrics.total_cost_usd` is *persisted* at import time, and the
    /// importer never revisits an unmodified transcript — so without this a
    /// price change silently applies to new sessions only, and
    /// `/sessions/:id/metrics` disagrees with `/turns` forever. a daemon
    /// records the applied revision in `settings` and re-costs every persisted
    /// row when it moves (see `repriceSessionMetricsIfNeeded`).
    public static let revision = 3

    public struct Price: Sendable {
        public let inputPerM: Double
        public let outputPerM: Double
        /// Cache reads bill at this fraction of `inputPerM` — 0.1× everywhere
        /// except Fable / Mythos 5.1 (0.025×) and Opus 5.5 (0.05×).
        public let cacheReadMultiplier: Double

        public init(inputPerM: Double, outputPerM: Double, cacheReadMultiplier: Double = 0.10) {
            self.inputPerM = inputPerM
            self.outputPerM = outputPerM
            self.cacheReadMultiplier = cacheReadMultiplier
        }
    }

    /// Cache writes bill at a premium over base input, and the premium depends
    /// on the entry's TTL: 1.25× for the default 5-minute cache, 2× for the
    /// 1-hour cache.
    ///
    /// `ttl` is the raw string the status line reports. Anthropic documents
    /// `"5m"` and `"1h"`; the field is undocumented in the status-line payload,
    /// so anything else — including a spelling Anthropic adds later — is treated
    /// as *unknown*, not as 5m. ``cacheWriteMultiplier(ttl:)`` returns the
    /// 5-minute rate for an unknown TTL because that is the API default, and
    /// ``isKnownTTL(_:)`` lets a caller that cares tell the two apart.
    public static func cacheWriteMultiplier(ttl: String?) -> Double {
        ttl == "1h" ? 2.00 : 1.25
    }

    /// Whether `ttl` is a spelling this table actually knows how to price. A
    /// `false` here means the cost that comes back is the *default* rate, not a
    /// measured one — `/insights/cache-misses` reports that distinction rather
    /// than quietly rounding an unrecognised TTL down to 1.25×.
    public static func isKnownTTL(_ ttl: String?) -> Bool {
        ttl == "1h" || ttl == "5m"
    }

    // Checked against https://platform.claude.com/docs/en/about-claude/pricing
    // on 2026-09-26.
    private static let table: [String: Price] = [
        // Fable / Mythos tier — $10/$50. The 5.1 generation discounts cache
        // reads to $0.25/MTok (0.025×); Fable 5 / Mythos 5 read at the usual 0.1×.
        "claude-fable-5-1": Price(inputPerM: 10.00, outputPerM: 50.00, cacheReadMultiplier: 0.025),
        "claude-mythos-5-1": Price(inputPerM: 10.00, outputPerM: 50.00, cacheReadMultiplier: 0.025),
        "claude-fable-5": Price(inputPerM: 10.00, outputPerM: 50.00),
        "claude-mythos-5": Price(inputPerM: 10.00, outputPerM: 50.00),

        // Opus. 5.5 is cheaper than 5 and reads cache at 0.05× ($0.20/MTok).
        // 4.5 through 5 share $5/$25; only 4.1 and older stay on $15/$75.
        "claude-opus-5-5": Price(inputPerM: 4.00, outputPerM: 20.00, cacheReadMultiplier: 0.05),
        "claude-opus-5": Price(inputPerM: 5.00, outputPerM: 25.00),
        "claude-opus-4-8": Price(inputPerM: 5.00, outputPerM: 25.00),
        "claude-opus-4-7": Price(inputPerM: 5.00, outputPerM: 25.00),
        "claude-opus-4-6": Price(inputPerM: 5.00, outputPerM: 25.00),
        "claude-opus-4-5": Price(inputPerM: 5.00, outputPerM: 25.00),
        "claude-opus-4-1": Price(inputPerM: 15.00, outputPerM: 75.00),
        "claude-opus-4": Price(inputPerM: 15.00, outputPerM: 75.00),
        "claude-3-opus": Price(inputPerM: 15.00, outputPerM: 75.00),

        // Sonnet.
        "claude-sonnet-5": Price(inputPerM: 2.00, outputPerM: 10.00),
        "claude-sonnet-4-6": Price(inputPerM: 3.00, outputPerM: 15.00),
        "claude-sonnet-4-5": Price(inputPerM: 3.00, outputPerM: 15.00),
        "claude-sonnet-4": Price(inputPerM: 3.00, outputPerM: 15.00),
        "claude-3-7-sonnet": Price(inputPerM: 3.00, outputPerM: 15.00),
        "claude-3-5-sonnet": Price(inputPerM: 3.00, outputPerM: 15.00),

        // Haiku.
        "claude-haiku-4-5": Price(inputPerM: 1.00, outputPerM: 5.00),
        "claude-3-5-haiku": Price(inputPerM: 0.80, outputPerM: 4.00),
        "claude-3-haiku": Price(inputPerM: 0.25, outputPerM: 1.25)
    ]

    /// Family keyword → the table id whose price stands in for a model this
    /// table has never seen. Pointing at a *table entry* rather than at a
    /// freshly-built `Price` is what keeps `cacheReadMultiplier` attached: a
    /// literal here would silently re-bill Fable 5.1's cache reads at 0.1×,
    /// four times their real rate.
    private static let familyFallbacks: [(keyword: String, id: String)] = [
        ("fable", "claude-fable-5-1"),
        ("mythos", "claude-mythos-5-1"),
        ("opus", "claude-opus-5-5"),
        ("sonnet", "claude-sonnet-5"),
        ("haiku", "claude-haiku-4-5")
    ]

    /// Strips a trailing `-YYYYMMDD` release date from a model id.
    ///
    /// Anthropic ships every model under both an undated alias
    /// (`claude-opus-4-5`) and a dated id (`claude-opus-4-5-20251101`), and it
    /// is the *dated* form transcripts record. Without this step every dated id
    /// misses ``table`` and lands on the family fallback, which prices it at the
    /// family's current generation — 96,681 captured Haiku turns, and Opus 4.5
    /// turns billed at Opus 5's $5/$25 instead of $15/$75.
    ///
    /// Only an exactly-8-digit final segment is stripped, so a version segment
    /// (`claude-opus-4-5`) and a local model (`qwen2.5-coder:32b`) are left
    /// alone.
    public static func canonicalModelID(_ model: String) -> String {
        guard let dash = model.lastIndex(of: "-") else { return model }
        let suffix = model[model.index(after: dash)...]
        guard suffix.count == 8, suffix.allSatisfy(\.isNumber) else { return model }
        return String(model[model.startIndex..<dash])
    }

    /// Whether a model is metered against the *Fable sub-limit* — the half of
    /// the weekly quota Anthropic reserves for its top tier.
    ///
    /// It lives here, beside `familyFallbacks`, because this is where the
    /// codebase already decides what family a recorded model id belongs to, and
    /// the sub-limit is a statement about a family rather than about any one
    /// id: transcripts record dated ids (`claude-fable-5-1-20260201`) and new
    /// generations ship without warning, so matching the exact ids in `table`
    /// would silently stop counting the day a new one appeared — and the row
    /// that reads too LOW is the one nobody notices.
    ///
    /// Mythos counts too: it is priced identically and drawn from the same
    /// allowance, so a gauge that counted only `fable` would under-report a
    /// week spent on it.
    ///
    /// **Anchored, not a substring.** The family must appear as a whole name —
    /// `claude-fable` / `claude-mythos`, starting the id or following a
    /// provider prefix's separator (`us.anthropic.claude-fable-5-1-v1:0`,
    /// `anthropic/claude-mythos-5-1`), and ending the id or followed by `-`. A
    /// local model that merely contains the word (`affable-coder-7b`) is not
    /// Anthropic's tier, and counting its cost would push the gauge toward a
    /// limit it cannot reach.
    public static func isFableTier(_ model: String) -> Bool {
        let lower = canonicalModelID(model).lowercased()
        return fableTierFamilies.contains { family in
            var searchFrom = lower.startIndex
            while let found = lower.range(of: family, range: searchFrom..<lower.endIndex) {
                let startsName = found.lowerBound == lower.startIndex
                    || !lower[lower.index(before: found.lowerBound)].isLetterOrDigitASCII
                let endsName = found.upperBound == lower.endIndex || lower[found.upperBound] == "-"
                if startsName && endsName { return true }
                searchFrom = lower.index(after: found.lowerBound)
            }
            return false
        }
    }

    private static let fableTierFamilies = ["claude-fable", "claude-mythos"]

    public static func price(for model: String) -> Price? {
        if let direct = table[model] { return direct }
        let canonical = canonicalModelID(model)
        if canonical != model, let dated = table[canonical] { return dated }
        let lower = canonical.lowercased()
        for fallback in familyFallbacks where lower.contains(fallback.keyword) {
            return table[fallback.id]
        }
        return nil
    }

    /// Compute USD cost for a turn. Cache reads bill at the model's
    /// `cacheReadMultiplier` of the input rate; cache writes at the TTL's
    /// premium (``cacheWriteMultiplier(ttl:)``).
    ///
    /// `cacheCreation1hTokens` is the **subset of `cacheCreationTokens`** written
    /// into the 1-hour cache, which transcripts report as
    /// `usage.cache_creation.ephemeral_1h_input_tokens`. It defaults to zero —
    /// the whole write billed at the 5-minute rate — because that is what a
    /// transcript predating the split says, and what the CSL-migration path can
    /// know. A caller that leaves it at the default on 1h traffic understates
    /// cache creation by 37.5%, so every path that has the number passes it.
    public static func cost(
        model: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int,
        cacheCreationTokens: Int,
        cacheCreation1hTokens: Int = 0
    ) -> Double {
        guard let pricing = price(for: model) else { return 0 }
        let million = 1_000_000.0
        // Clamp rather than trust: the two numbers come from different JSONL
        // fields, and a total that lags its own 1h component would otherwise
        // bill negative 5-minute tokens.
        let oneHour = min(max(cacheCreation1hTokens, 0), max(cacheCreationTokens, 0))
        let fiveMinute = max(cacheCreationTokens, 0) - oneHour
        return (
            Double(inputTokens)     * pricing.inputPerM  / million
          + Double(outputTokens)    * pricing.outputPerM / million
          + Double(cacheReadTokens) * pricing.inputPerM * pricing.cacheReadMultiplier / million
          + Double(oneHour)         * pricing.inputPerM * cacheWriteMultiplier(ttl: "1h") / million
          + Double(fiveMinute)      * pricing.inputPerM * cacheWriteMultiplier(ttl: "5m") / million
        )
    }

    /// USD cost of writing `tokens` into the cache on `model` at `ttl` — what a
    /// cache miss actually costs, since a miss re-writes the whole prefix.
    /// Returns 0 for a model with no known price.
    public static func cacheWriteCost(model: String, tokens: Int, ttl: String?) -> Double {
        guard let pricing = price(for: model) else { return 0 }
        return Double(tokens) * pricing.inputPerM * cacheWriteMultiplier(ttl: ttl) / 1_000_000.0
    }
}

private extension Character {
    /// `[a-z0-9]` — what may NOT stand directly before a model family's name.
    var isLetterOrDigitASCII: Bool {
        isASCII && (isLetter || isNumber)
    }
}
#endif
