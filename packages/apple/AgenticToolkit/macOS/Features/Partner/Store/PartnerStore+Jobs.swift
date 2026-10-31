import Foundation
import AgenticToolkitCore

extension PartnerStore {

    public func jobs() throws -> [PartnerJob] {
        try locked {
            try runQuery("""
                SELECT id, name, is_enabled, schedule_seconds, guidelines, steps_json, is_builtin
                FROM job ORDER BY is_builtin DESC, name, id
            """, []) { row in
                let steps = try JSONDecoder().decode([PartnerJobStep].self, from: Data(row.text(5).utf8))
                return PartnerJob(id: row.text(0), name: row.text(1), isEnabled: row.int(2) != 0,
                                  scheduleSeconds: row.optInt(3).map { Int($0) }, guidelines: row.text(4),
                                  steps: steps, isBuiltIn: row.int(6) != 0)
            }
        }
    }

    public func upsert(_ job: PartnerJob) throws {
        let steps = try Self.json(job.steps)
        try write(.jobs) {
            try run("""
                INSERT OR REPLACE INTO job (id, name, is_enabled, schedule_seconds, guidelines, steps_json,
                    is_builtin, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [.text(job.id), .text(job.name), .int(job.isEnabled ? 1 : 0),
                  job.scheduleSeconds.map { .int(Int64($0)) } ?? .null, .text(job.guidelines), .text(steps),
                  .int(job.isBuiltIn ? 1 : 0), .date(Date())])
        }
    }

    public func deleteJob(id: String) throws {
        try write(.jobs) { try run("DELETE FROM job WHERE id = ?", [.text(id)]) }
    }
}
