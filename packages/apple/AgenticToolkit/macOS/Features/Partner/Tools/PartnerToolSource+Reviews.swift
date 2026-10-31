import Foundation
import AgenticToolkitCore

extension PartnerToolSource {

    private struct ReviewQueue: Encodable {
        var reviews: [PartnerReview]
        var concurrency: Int
        var running: Int
    }

    /// The `partner_review_*` tools, answered by `service`.
    static func reviewTools(_ service: ReviewService) -> [(ToolDefinition, Handler)] {
        let id = ToolJSONSchema.string("The review's id, from partner_review_next.")
        return [
            (ToolDefinition(
                name: "partner_review_next",
                description: "Lists the queued reviews, oldest first, with the concurrency limit and how many "
                    + "are running.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
             { _ in
                 do {
                     let next = try await MainActor.run { try service.next() }
                     return Self.encode(ReviewQueue(reviews: next.reviews, concurrency: next.concurrency,
                                                    running: next.running))
                 } catch {
                     return Self.failure("partner_review_next failed: \(error.localizedDescription)")
                 }
             }),
            (ToolDefinition(
                name: "partner_review_start",
                description: "Starts one queued review: prepares the repo's review worktree at the branch tip, "
                    + "opens a session in it and returns the review, the worktree, the fix branch, the diff of "
                    + "its files to the tip and the job's steps filled in. A commit no longer in its branch "
                    + "comes back skipped, with no session and no steps.",
                parametersJSONSchema: ToolJSONSchema.object(properties: ["id": id], required: ["id"])),
             { data in
                 guard let reviewID = Self.arguments(data)["id"] as? String, !reviewID.isEmpty else {
                     return Self.failure("id is required")
                 }
                 do {
                     return Self.encode(try await service.start(id: reviewID))
                 } catch {
                     return Self.failure("partner_review_start failed: \(error.localizedDescription)")
                 }
             }),
            (ToolDefinition(
                name: "partner_review_finish",
                description: "Sets a review to done, failed or skipped with a summary, and leaves the owner a "
                    + "\"review done\" notification. Closes nothing.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "id": id,
                    "state": ToolJSONSchema.string("One of: done, failed, skipped."),
                    "summary": ToolJSONSchema.string("One paragraph: what was fixed, what was skipped and why.")
                ], required: ["id", "state", "summary"])),
             { data in
                 let args = Self.arguments(data)
                 guard let reviewID = args["id"] as? String, !reviewID.isEmpty else {
                     return Self.failure("id is required")
                 }
                 guard let stateName = args["state"] as? String,
                       let state = PartnerReviewState(rawValue: stateName),
                       [.done, .failed, .skipped].contains(state) else {
                     return Self.failure("state must be one of: done, failed, skipped")
                 }
                 let summary = args["summary"] as? String ?? ""
                 do {
                     let review = try await MainActor.run {
                         try service.finish(id: reviewID, state: state, summary: summary)
                     }
                     return Self.encode(review)
                 } catch {
                     return Self.failure("partner_review_finish failed: \(error.localizedDescription)")
                 }
             })
        ]
    }
}
