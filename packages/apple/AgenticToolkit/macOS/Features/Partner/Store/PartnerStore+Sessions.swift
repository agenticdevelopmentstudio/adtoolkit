import Foundation

extension PartnerStore {

    /// A terminal session the partner opened.
    public struct SessionRecord: Codable, Sendable, Equatable, Identifiable {
        public var id: String
        public var title: String
        public var directory: String
        public var openedAt: Date
        public var closedAt: Date?
        public var finalScreen: String?
        public var reviewID: String?

        public init(id: String, title: String, directory: String, openedAt: Date, closedAt: Date? = nil,
                    finalScreen: String? = nil, reviewID: String? = nil) {
            self.id = id
            self.title = title
            self.directory = directory
            self.openedAt = openedAt
            self.closedAt = closedAt
            self.finalScreen = finalScreen
            self.reviewID = reviewID
        }
    }

    public func upsert(_ session: SessionRecord) throws {
        try write(.sessions) {
            try run("""
                INSERT OR REPLACE INTO partner_session (id, title, directory, opened_at, closed_at,
                    final_screen, review_id) VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [.text(session.id), .text(session.title), .text(session.directory), .date(session.openedAt),
                  .optDate(session.closedAt), .optText(session.finalScreen), .optText(session.reviewID)])
        }
    }

    /// Newest first.
    public func sessions() throws -> [SessionRecord] {
        try locked {
            try runQuery("""
                SELECT id, title, directory, opened_at, closed_at, final_screen, review_id
                FROM partner_session ORDER BY opened_at DESC, id
            """, []) { row in
                SessionRecord(id: row.text(0), title: row.text(1), directory: row.text(2),
                              openedAt: try row.date(3), closedAt: try row.optDate(4),
                              finalScreen: row.optText(5), reviewID: row.optText(6))
            }
        }
    }

    public func purgeSessions(closedBefore date: Date) throws -> Int {
        try write(.sessions) {
            try run("DELETE FROM partner_session WHERE closed_at IS NOT NULL AND closed_at < ?", [.date(date)])
        }
    }
}
