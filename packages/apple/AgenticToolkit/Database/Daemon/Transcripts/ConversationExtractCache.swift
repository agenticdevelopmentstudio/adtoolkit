#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// `ConversationExtractor.extract` results, remembered by transcript line.
///
/// The Conversations window re-reads its whole feed on every poll, and each read
/// parses up to `limit × 12` `raw_json` lines — tens of KB of JSON apiece — to
/// find the few hundred that are conversation. Almost all of them are the same
/// lines the previous poll parsed: ~1 of every 20 sampled daemon seconds went to
/// re-parsing them while the window was open. `transcript_lines` rows are
/// insert-only (`INSERT OR IGNORE`), so a line's parse never goes stale; the
/// raw length rides along in the key only so a rowid reused after retention
/// can't be served another line's text.
///
/// The bounded, lock-guarded store is the toolkit's `LRUCache`; what stays
/// here is the key and the extractor. Its eviction is O(n) — about 15 µs per
/// miss at 12,000 entries, well under the JSON parse every miss already pays.
public final class ConversationExtractCache: Sendable {
    private struct Key: Hashable, Sendable {
        let lineId: Int
        let rawLength: Int
    }

    private let cache: LRUCache<Key, [ConversationExtractor.Line]>

    public init(capacity: Int = 12_000) {
        cache = LRUCache(capacity: capacity)
    }

    public var capacity: Int { cache.capacity }

    public func lines(lineId: Int, rawJSON: String) -> [ConversationExtractor.Line] {
        let key = Key(lineId: lineId, rawLength: rawJSON.utf8.count)
        if let hit = cache.value(for: key) { return hit }
        // Parsed outside any lock: concurrent feed reads must not queue behind
        // one another's JSON.
        let parsed = ConversationExtractor.extract(rawJSON: rawJSON)
        cache.set(parsed, for: key)
        return parsed
    }

    /// Entries held — for tests.
    public var count: Int { cache.count }
}
#endif
