import Combine
import Foundation
import AgenticToolkitCore

/// What the Jobs tab edits: the store's jobs, with each job's guidelines read from and written to its
/// `jobs/<id>.md` file, which is where the partner reads them from.
@MainActor
public final class PartnerJobsEditorModel: ObservableObject {

    public enum EditorError: Error, Equatable {
        case unknownJob(String)
        case noDefault(String)
        case stepIndexOutOfRange(Int)
    }

    @Published public var jobs: [PartnerJob] = []
    @Published public var selectedID: String?

    private let store: PartnerStore
    private let guidelines: PartnerGuidelinesInstaller

    public init(store: PartnerStore, guidelines: PartnerGuidelinesInstaller) {
        self.store = store
        self.guidelines = guidelines
        reload()
        selectedID = jobs.first?.id
    }

    /// Re-reads the store and the guidelines files; keeps the selection when its job is still there.
    public func reload() {
        let stored = (try? store.jobs()) ?? []
        jobs = guidelines.loadGuidelines(jobs: stored)
        if let selectedID, !jobs.contains(where: { $0.id == selectedID }) { self.selectedID = jobs.first?.id }
    }

    /// Upserts the job into the store and writes its guidelines text to its file.
    public func save(_ job: PartnerJob) throws {
        try store.upsert(job)
        try guidelines.saveGuidelines(jobID: job.id, text: job.guidelines)
        reload()
    }

    /// Restores a built-in job to its bundled default, and removes its edited guidelines file.
    public func resetToDefault(id: String) throws {
        guard let original = PartnerJobDefaults.all.first(where: { $0.id == id }) else {
            throw EditorError.noDefault(id)
        }
        try store.upsert(original)
        try guidelines.resetGuidelines(jobID: id)
        reload()
    }

    public func addStep(to jobID: String) throws {
        try update(jobID) {
            $0.steps.append(PartnerJobStep(name: "new step", environment: .terminal, command: "", condition: ""))
        }
    }

    public func removeStep(in jobID: String, at index: Int) throws {
        try update(jobID) { job in
            guard job.steps.indices.contains(index) else { throw EditorError.stepIndexOutOfRange(index) }
            job.steps.remove(at: index)
        }
    }

    /// Moves the step at `from` so it ends up at index `to`.
    public func moveStep(in jobID: String, from: Int, to: Int) throws { // swiftlint:disable:this identifier_name
        try update(jobID) { job in
            for index in [from, to] where !job.steps.indices.contains(index) {
                throw EditorError.stepIndexOutOfRange(index)
            }
            job.steps.insert(job.steps.remove(at: from), at: to)
        }
    }

    /// Persists a change to a job in the store only (steps, schedule, enabled).
    /// The guidelines file is not touched, so a job that has none keeps following its stored default.
    /// The store is re-read first, so a write made elsewhere since the last reload (the coordinator rewriting
    /// the code-reviews schedule, say) is changed rather than overwritten with the stale copy.
    public func update(_ jobID: String, _ change: (inout PartnerJob) throws -> Void) throws {
        reload()
        guard var job = jobs.first(where: { $0.id == jobID }) else { throw EditorError.unknownJob(jobID) }
        try change(&job)
        try store.upsert(job)
        reload()
    }
}
